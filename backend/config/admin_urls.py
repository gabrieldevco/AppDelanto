from django.urls import path
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from users.views import user_management, verify_company

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard(request):
    """Obtener estadísticas del dashboard para admin"""
    from django.db.models import Count, Sum, Avg
    from users.models import User
    from companies.models import Company
    from advances.models import Advance
    from notifications.models import Notification
    
    if not request.user.is_admin:
        return Response({'error': 'No autorizado'}, status=403)
    
    # Estadísticas de usuarios
    total_users = User.objects.count()
    employees = User.objects.filter(role='employee').count()
    employers = User.objects.filter(role='employer').count()
    
    # Estadísticas de empresas
    total_companies = Company.objects.count()
    verified_companies = Company.objects.filter(is_verified=True).count()
    
    # Estadísticas de adelantos
    total_advances = Advance.objects.count()
    pending_advances = Advance.objects.filter(status='pending').count()
    approved_advances = Advance.objects.filter(status='approved').count()
    disbursed_advances = Advance.objects.filter(status='disbursed').count()
    
    # Monto total desembolsado
    total_disbursed = Advance.objects.filter(status='disbursed').aggregate(
        total=Sum('amount')
    )['total'] or 0
    
    # Notificaciones recientes
    recent_notifications = Notification.objects.order_by('-created_at')[:5]
    
    return Response({
        'users': {
            'total': total_users,
            'employees': employees,
            'employers': employers,
        },
        'companies': {
            'total': total_companies,
            'verified': verified_companies,
            'pending': total_companies - verified_companies,
        },
        'advances': {
            'total': total_advances,
            'pending': pending_advances,
            'approved': approved_advances,
            'disbursed': disbursed_advances,
            'total_disbursed': total_disbursed,
        },
        'recent_notifications': [
            {
                'id': n.id,
                'title': n.title,
                'message': n.message,
                'type': n.type,
                'created_at': n.created_at,
            }
            for n in recent_notifications
        ],
    })

urlpatterns = [
    path('dashboard/', dashboard, name='dashboard'),
    path('user-management/', user_management, name='user-management'),
    path('verify-company/<int:company_id>/', verify_company, name='verify-company'),
]
