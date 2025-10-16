from django.contrib import admin
from django.urls import path, include
from django.contrib.auth import views as auth_views
from overtime_app import views
from overtime_app.views import LogoutView

urlpatterns = [
    path('', views.home, name='home'),
    path('reset-password/', views.reset_password, name='reset_password_root'),
    path('login/', views.portal_login, name='portal_login'),
    path('', LogoutView.as_view(next_page='home'), name='logout'),
    path('admin/', admin.site.urls),
    path('lk/', include('overtime_app.urls')),
]