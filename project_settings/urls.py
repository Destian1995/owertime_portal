from django.contrib import admin
from django.urls import path, include
from overtime_app import views
from overtime_app.views import LogoutView
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('', views.home, name='home'),
    path('reset-password/', views.reset_password, name='reset_password_root'),
    path('login/', views.portal_login, name='portal_login'),
    path('', LogoutView.as_view(next_page='home'), name='logout'),
    path('admin/', admin.site.urls),
    path('lk/', include('overtime_app.urls')),
    path("lk/file/<str:filename>/", views.serve_text_file, name="serve_text_file"),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)