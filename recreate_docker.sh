#!/bin/bash

# Путь к директории проекта (где находится Dockerfile)
PROJECT_DIR="$HOME/owertime_portal"

# Имя образа
IMAGE_NAME="overtime_portal_image"

# Тег образа
IMAGE_TAG="latest"

# Полное имя образа
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# Имя контейнера
CONTAINER_NAME="my_overtime_container"

# Порт приложения внутри контейнера
APP_PORT="8000"

# Порт хоста
HOST_PORT="8000"

# Путь к .env файлу (предполагается, что он в PROJECT_DIR)
ENV_FILE="$PROJECT_DIR/.env"

# Команды для выполнения миграций
MAKEMIGRATIONS_COMMAND="python manage.py makemigrations"
MIGRATE_COMMAND="python manage.py migrate"
COLLECTSTATIC_COMMAND="python manage.py collectstatic --noinput" # Добавленная команда

echo "=== Начинаю процесс пересоздания Docker-контейнера ==="

# Перейти в директорию проекта
echo "Переход в директорию проекта: $PROJECT_DIR"
cd "$PROJECT_DIR" || { echo "Ошибка: не удалось перейти в директорию $PROJECT_DIR"; exit 1; }

# Остановить и удалить старый контейнер, если он существует
if [ "$(sudo docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "Останавливаю старый контейнер: $CONTAINER_NAME"
    sudo docker stop $CONTAINER_NAME
    echo "Удаляю старый контейнер: $CONTAINER_NAME"
    sudo docker rm $CONTAINER_NAME
else
    echo "Контейнер с именем $CONTAINER_NAME не найден, продолжаем..."
fi

# Удалить старый образ, если он существует
if [ "$(sudo docker images -q $IMAGE_NAME 2>/dev/null)" ]; then
    echo "Удаляю старый образ: $FULL_IMAGE_NAME"
    sudo docker rmi $IMAGE_NAME
else
    echo "Образ с именем $IMAGE_NAME не найден, продолжаем..."
fi

# Собрать новый образ
echo "Собираю новый образ: $FULL_IMAGE_NAME"
sudo docker build -t $FULL_IMAGE_NAME .

# Проверить, успешно ли собран образ
if [ $? -eq 0 ]; then
    echo "Образ успешно собран."
else
    echo "Ошибка при сборке образа. Прекращаю выполнение."
    exit 1
fi

# Запустить новый контейнер
echo "Запускаю новый контейнер: $CONTAINER_NAME"
# Проверяем, существует ли .env файл
if [ -f "$ENV_FILE" ]; then
    echo "Использую .env файл: $ENV_FILE"
    sudo docker run -d \
        --name $CONTAINER_NAME \
        -p $HOST_PORT:$APP_PORT \
        --add-host host.docker.internal:host-gateway \
        --env-file "$ENV_FILE" \
        $FULL_IMAGE_NAME
else
    echo "Предупреждение: .env файл $ENV_FILE не найден. Запускаю контейнер без него."
    sudo docker run -d \
        --name $CONTAINER_NAME \
        -p $HOST_PORT:$APP_PORT \
        --add-host host.docker.internal:host-gateway \
        $FULL_IMAGE_NAME
fi

# Проверить, успешно ли запущен контейнер
if [ $? -eq 0 ]; then
    echo "=== Контейнер успешно запущен ==="
    # Вывести статус
    sudo docker ps -f name=$CONTAINER_NAME
else
    echo "Ошибка при запуске контейнера."
    exit 1
fi

# Ждем несколько секунд, чтобы контейнер полностью стартовал
echo "Жду 10 секунд, чтобы приложение внутри контейнера стартовало..."
sleep 10

# Выполнить makemigrations внутри запущенного контейнера
echo "Генерирую миграции в контейнере $CONTAINER_NAME..."
sudo docker exec $CONTAINER_NAME $MAKEMIGRATIONS_COMMAND

if [ $? -eq 0 ]; then
    echo "=== Генерация миграций завершена ==="
else
    echo "Ошибка при генерации миграций в контейнере $CONTAINER_NAME"
    # Опционально: можно остановить контейнер в случае ошибки
    # sudo docker stop $CONTAINER_NAME
    exit 1
fi

# Выполнить migrate внутри запущенного контейнера
echo "Применяю миграции в контейнере $CONTAINER_NAME..."
sudo docker exec $CONTAINER_NAME $MIGRATE_COMMAND

if [ $? -eq 0 ]; then
    echo "=== Миграции успешно применены ==="
else
    echo "Ошибка при применении миграций в контейнере $CONTAINER_NAME"
    exit 1
fi

# Выполнить collectstatic внутри запущенного контейнера
echo "Собираю статические файлы в контейнере $CONTAINER_NAME..."
sudo docker exec $CONTAINER_NAME $COLLECTSTATIC_COMMAND

if [ $? -eq 0 ]; then
    echo "=== Статические файлы успешно собраны ==="
else
    echo "Ошибка при сборе статических файлов в контейнере $CONTAINER_NAME"
    exit 1
fi

echo "=== Процесс пересоздания Docker-контейнера, выполнения миграций и сбора статики завершен ==="