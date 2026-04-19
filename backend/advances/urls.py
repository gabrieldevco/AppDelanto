from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'advances', views.AdvanceViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('advances-stats/', views.advance_stats, name='advance-stats'),
    path('advances/pending/', views.pending_advances, name='pending-advances'),
    path('advances/<int:pk>/approve/', views.approve_advance, name='approve-advance'),
    path('advances/<int:pk>/reject/', views.reject_advance, name='reject-advance'),
    path('advances/<int:pk>/disburse/', views.disburse_advance, name='disburse-advance'),
]
