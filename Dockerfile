# ============ 1. Базовый образ ============
FROM python:3.12-slim

# ============ 2. Переменные окружения ============
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

# ============ 3. Рабочая директория ============
WORKDIR /app

# ============ 4. Системные зависимости ============
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    gcc \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# ============ 5. Установка зависимостей ============
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
 && rm -rf /root/.cache/pip

# ============ 6. Копируем код проекта ============
COPY . .

# ============ 7. Сборка статики ============
RUN python manage.py collectstatic --noinput || true

# ============ 8. Открываем порт ============
EXPOSE 8000

# ============ 9. Запуск приложения ============
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "project_settings.wsgi:application"]
