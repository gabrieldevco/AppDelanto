from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'users', views.UserViewSet)
router.register(r'employee-profiles', views.EmployeeProfileViewSet)
router.register(r'admin-profiles', views.AdminProfileViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('auth/register/', views.register, name='register'),
    path('auth/login/', views.login, name='login'),
    path('auth/logout/', views.logout, name='logout'),
    path('auth/me/', views.me, name='me'),
    path('admin/user-management/', views.user_management, name='user-management'),
    path('admin/verify-company/<int:company_id>/', views.verify_company, name='verify-company'),
]
