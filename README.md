# Overtime Portal - Портал управления переработками

Django приложение для управления запросами сотрудников на работу в выходные/праздничные дни с системой согласования и уведомления руководителей.

---

## 📋 Описание проекта

**Overtime Portal** предназначен для:
- Создания и управления заявками на переработку
- Согласования запросов руководителями
- Отслеживания часов переработок по сотрудникам
- Генерации отчётов в Word формате
- Отправки email уведомлений при изменении статуса
- Учета праздничных и выходных дней

**Целевая аудитория:** HR отделы, руководители, сотрудники компаний

---

## 🏗️ Архитектура проекта

```
owertime_portal/
├── manage.py                 # Django управление проектом
├── requirements.txt          # Python зависимости
├── Dockerfile               # Docker конфигурация
├── recreate_docker.sh       # Скрипт пересоздания контейнера
├── .env                     # Переменные окружения
├── .gitignore              # Git ignore правила
├── backup.sql              # Бекап базы данных
├── fix_encoding.py         # Утилита исправления кодировки
│
├── project_settings/        # Конфигурация Django
│   ├── settings.py         # Основные настройки
│   ├── urls.py             # Главные URL маршруты
│   └── wsgi.py             # WSGI конфигурация
│
├── overtime_app/            # Основное приложение
│   ├── models.py           # Модели данных
│   ├── views.py            # Представления
│   ├── urls.py             # URL маршруты приложения
│   ├── forms.py            # Формы Django
│   ├── admin.py            # Админ-панель
│   ├── README.md           # Документация приложения
│   ├── migrations/         # Миграции БД
│   ├── management/         # Команды управления
│   ├── media/              # Загруженные файлы
│   └── templates/          # HTML шаблоны
│
├── static/                 # Статические файлы (CSS, JS, images)
├── staticfiles/           # Собранная статика для production
└── media/                 # Медиа файлы
```

---

## 🗄️ Модели данных

### Position (Должность)
```python
Position:
  - name: CharField (уникальное значение)
```
Хранит справочник должностей сотрудников.

### Holiday (Праздничные дни)
```python
Holiday:
  - date: DateField (уникальное)
  - is_holiday: BooleanField (true = выходной)
```
Учет праздничных и выходных дней для расчета часов.

### Employee (Сотрудник)
```python
Employee:
  - full_name: CharField
  - department: CharField
  - manager1: ForeignKey('self') - первый руководитель
  - manager2: ForeignKey('self') - второй руководитель
  - email: EmailField (уникальное)
  - job_title_manual: CharField
  - role_type: CharField (choices: 'employee', 'manager')
  
  Properties:
  - is_manager: bool (true, если role_type == 'manager')
```
Информация о сотрудниках, их руководителях и ролях в системе.

### OvertimeRequest (Заявка на переработку)
```python
OvertimeRequest:
  - employee: ForeignKey(Employee)
  - created_at: DateTimeField (автоматически)
  - start_datetime: DateTimeField
  - end_datetime: DateTimeField
  - reason: CharField (choices):
      * 'holiday' - Работа в выходной и праздничный день
      * 'incident' - Работы по устранению инцидентов
      * 'maintenance' - Регламентные работы
      * 'on_call' - Дежурство в торговые выходные дни
  - justification: TextField
  - status: CharField (choices):
      * 'pending' - На согласовании
      * 'approved' - Согласовано
      * 'rejected' - Отклонено
  - hours: FloatField (вычисляется автоматически)
  - attachment: FileField (опционально)
  
  Methods:
  - save(): вычисляет часы между start_datetime и end_datetime
  - get_attachment_view_url(): возвращает URL для просмотра файла
```
Основная модель - заявки на переработку с временем, причиной и статусом согласования.

### ApprovalLog (Лог согласований)
Историческая запись всех действий согласования.

### ApprovalToken (Токен согласования)
Секретные токены для согласования через email ссылки.

---

## 📦 Технологический стек

### Backend
- **Python 3.12**
- **Django 4.2+** - веб-фреймворк
- **PostgreSQL** (посредством psycopg2-binary) - база данных
- **Gunicorn** - WSGI сервер для production
- **WhiteNoise** - раздача статических файлов

### Frontend
- **Django Template Engine** - шаблонизатор
- **django-widget-tweaks** - улучшение формы в шаблонах

### Утилиты
- **openpyxl** - работа с Excel файлами
- **python-docx** - генерация Word документов
- **workalendar** - учет праздников и выходных
- **python-decouple** - управление переменными окружения

### DevOps
- **Docker** - контейнеризация
- **Docker Compose** - управление контейнерами

---

## ⚙️ Конфигурация и переменные окружения

Файл `.env` должен содержать:

```env
# Django
DEBUG=False
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
DATABASE_URL=postgresql://user:password@localhost:5432/overtime_db

# Email
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-password

# Sites Framework
SITE_ID=1
SITE_DOMAIN=yourdomain.com

# Security
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
```

---

## 🚀 Установка и запуск

### Локальное развитие

1. **Клонирование репозитория**
   ```bash
   git clone <repo-url>
   cd owertime_portal
   ```

2. **Создание виртуального окружения**
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/Mac
   # или
   venv\Scripts\activate  # Windows
   ```

3. **Установка зависимостей**
   ```bash
   pip install -r requirements.txt
   ```

4. **Конфигурирование .env файла**
   ```bash
   cp .env.example .env
   # Отредактируйте .env с вашими значениями
   ```

5. **Миграции БД**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

6. **Создание суперпользователя**
   ```bash
   python manage.py createsuperuser
   ```

7. **Сбор статики**
   ```bash
   python manage.py collectstatic
   ```

8. **Запуск development сервера**
   ```bash
   python manage.py runserver
   ```

### Docker запуск

1. **Сборка и запуск контейнера**
   ```bash
   docker-compose up --build
   ```

2. **Применение миграций в контейнере**
   ```bash
   docker-compose exec web python manage.py migrate
   docker-compose exec web python manage.py createsuperuser
   ```

3. **Доступ к приложению**
   - http://localhost:8000

### Пересоздание Docker контейнера
```bash
bash recreate_docker.sh
```

---

## 📝 Основные функции

### 1. Управление заявками на переработку
- ✅ Создание новой заявки с датой, временем, причиной и обоснованием
- ✅ Загрузка прикрепленных файлов к заявке
- ✅ Просмотр статуса запроса
- ✅ Редактирование pending заявок
- ✅ Удаление собственных заявок

### 2. Система согласования
- ✅ Email уведомления руководителям о новых заявках
- ✅ Согласование/отклонение через веб-интерфейс или email токены
- ✅ Коментарии при отклонении
- ✅ История всех действий согласования

### 3. Отчетность
- ✅ Генерация отчетов в формате Word (.docx)
- ✅ Отчеты по сотрудникам и периодам
- ✅ Статистика переработок

### 4. Управление справочниками
- ✅ Справочник должностей
- ✅ Справочник праздничных и выходных дней
- ✅ Справочник сотрудников с ролями

### 5. Аутентификация
- ✅ Вход в систему по username/password
- ✅ Смена пароля
- ✅ Восстановление пароля

---

## 🔐 Разработка и тестирование

### Создание миграций после изменения моделей
```bash
python manage.py makemigrations
python manage.py migrate
```

### Запуск тестов (если есть)
```bash
python manage.py test
```

### Проверка кода
```bash
# Список возможных проблем
python manage.py check
```

### Исправление кодировки текстовых файлов
```bash
python fix_encoding.py
```

---

## 📂 Важные файлы

- **manage.py** - Entry point для Django команд
- **requirements.txt** - Все Python зависимости
- **Dockerfile** - Конфигурация контейнера
- **project_settings/settings.py** - Основные Django настройки
- **.env** - Переменные окружения (не коммитится в Git)
- **backup.sql** - Резервная копия БД

---

## 📜 Лицензия

BSD License

---

## 👥 Разработка

**Исходный автор:** Проектный команда  
**Последнее обновление:** 31.03.2026

Для вопросов и предложений создавайте issues или свяжитесь с командой разработки.

---

## 🐛 Troubleshooting

### Проблема: Ошибки кодировки при загрузке файлов
**Решение:**
```bash
python fix_encoding.py
```

### Проблема: Статика не отображается
**Решение:**
```bash
python manage.py collectstatic --clear --noinput
```

### Проблема: БД не синхронизирована
**Решение:**
```bash
python manage.py migrate
python manage.py migrate --fake-initial  # Если необходимо
```

### Проблема: Email уведомления не отправляются
**Решение:** Проверьте переменные окружения для email в `.env` файле и логи приложения.

---

## 📞 Контакты и поддержка

Для получения помощи:
1. Проверьте этот README
2. Посмотрите документацию в `overtime_app/README.md`
3. Создайте issue в репозитории
4. Свяжитесь с командой разработки
