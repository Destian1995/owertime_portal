FROM python:3.11-slim

# Устанавливаем рабочую директорию внутри контейнера
WORKDIR /app

# Копируем файл зависимостей в рабочую директорию
COPY requirements.txt .

# Устанавливаем зависимости Python
# psycopg2-binary может потребовать установку системных пакетов
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir -r requirements.txt

# Копируем исходный код проекта в рабочую директорию
COPY . .

# Указываем команду, которая будет выполнена при запуске контейнера
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "project_settings.wsgi:application"]