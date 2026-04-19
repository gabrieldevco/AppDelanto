from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'companies', views.CompanyViewSet)
router.register(r'company-settings', views.CompanySettingsViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('companies/<int:pk>/stats/', views.company_stats, name='company-stats'),
    path('my-company/', views.my_company, name='my-company'),
    path('companies/available/', views.available_companies, name='available-companies'),
]
