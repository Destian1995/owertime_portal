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
elif [ "$(sudo docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "Удаляю остановленный контейнер: $CONTAINER_NAME"
    sudo docker rm $CONTAINER_NAME
else
    echo "Контейнер с именем $CONTAINER_NAME не найден, продолжаем..."
fi

# Удалить старый образ, если он существует
if [ "$(sudo docker images -q $IMAGE_NAME 2>/dev/null)" ]; then
    echo "Удаляю старый образ: $FULL_IMAGE_NAME"
    sudo docker rmi $FULL_IMAGE_NAME
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

# Запустить новый контейнер с volume для статики
echo "Запускаю новый контейнер: $CONTAINER_NAME"
if [ -f "$ENV_FILE" ]; then
    echo "Использую .env файл: $ENV_FILE"
    sudo docker run -d \
        --name $CONTAINER_NAME \
        -p $HOST_PORT:$APP_PORT \
        --add-host host.docker.internal:host-gateway \
        --env-file "$ENV_FILE" \
        -v ${CONTAINER_NAME}_static:/app/staticfiles \
        $FULL_IMAGE_NAME
else
    echo "Предупреждение: .env файл $ENV_FILE не найден. Запускаю контейнер без него."
    sudo docker run -d \
        --name $CONTAINER_NAME \
        -p $HOST_PORT:$APP_PORT \
        --add-host host.docker.internal:host-gateway \
        -v ${CONTAINER_NAME}_static:/app/staticfiles \
        $FULL_IMAGE_NAME
fi

# Проверить, успешно ли запущен контейнер
if [ $? -eq 0 ]; then
    echo "=== Контейнер успешно запущен ==="
    sudo docker ps -f name=$CONTAINER_NAME
else
    echo "Ошибка при запуске контейнера."
    exit 1
fi

# Ждем несколько секунд, чтобы контейнер полностью стартовал
echo "Жду 10 секунд, чтобы приложение внутри контейнера стартовало..."
sleep 10

# Проверить, что контейнер запущен и работает
if [ ! "$(sudo docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "Ошибка: контейнер $CONTAINER_NAME не запущен. Проверьте логи:"
    sudo docker logs $CONTAINER_NAME
    exit 1
fi

# Выполнить сборку статики внутри контейнера
echo "Собираю статические файлы в контейнере..."
sudo docker exec $CONTAINER_NAME python manage.py collectstatic --noinput --clear

if [ $? -eq 0 ]; then
    echo "=== Статические файлы успешно собраны ==="
else
    echo "Ошибка при сборе статических файлов"
fi

# Выполнить миграции
echo "Применяю миграции..."
sudo docker exec $CONTAINER_NAME python manage.py migrate

if [ $? -eq 0 ]; then
    echo "=== Миграции успешно применены ==="
else
    echo "Ошибка при применении миграций"
fi

echo "=== Процесс завершен ==="
echo "Приложение доступно по адресу: http://localhost:$HOST_PORT"
echo "Админка: http://localhost:$HOST_PORT/admin"
echo "Для проверки статики: http://localhost:$HOST_PORT/static/admin/css/base.css"
echo "Логи: sudo docker logs -f $CONTAINER_NAME"