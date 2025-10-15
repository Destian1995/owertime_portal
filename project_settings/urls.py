from django.contrib import admin
from django.urls import path, include
from django.contrib.auth import views as auth_views
from overtime_app.views import home, portal_login, register

urlpatterns = [
    path('', home, name='home'),
    path('login/', portal_login, name='portal_login'),
    path('register/', register, name='register'),
    path('logout/', auth_views.LogoutView.as_view(next_page='home'), name='logout'),  # ← Добавь next_page
    path('admin/', admin.site.urls),
    path('lk/', include('overtime_app.urls')),
]