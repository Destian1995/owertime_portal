from django.contrib import admin
from django.urls import path, include
from django.contrib.auth import views as auth_views
from overtime_app.views import home, portal_login, register
from overtime_app.views import LogoutView

urlpatterns = [
    path('', home, name='home'),
    path('login/', portal_login, name='portal_login'),
    path('register/', register, name='register'),
    path('logout/', LogoutView.as_view(next_page='home'), name='logout'),
    path('admin/', admin.site.urls),
    path('lk/', include('overtime_app.urls')),
]