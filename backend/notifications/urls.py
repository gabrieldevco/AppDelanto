from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'notifications', views.NotificationViewSet, basename='notification')
router.register(r'system-notifications', views.SystemNotificationViewSet, basename='system-notification')

urlpatterns = [
    path('', include(router.urls)),
    path('my-notifications/', views.my_notifications, name='my-notifications'),
    path('notifications/<int:pk>/read/', views.mark_notification_read, name='mark-notification-read'),
    path('notifications/mark-all-read/', views.mark_all_read, name='mark-all-read'),
    path('notifications/unread-count/', views.unread_count, name='unread-count'),
]
