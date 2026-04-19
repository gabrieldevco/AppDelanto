from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied

from .models import Company, CompanySettings
from .serializers import CompanySerializer, CompanyListSerializer, CompanySettingsSerializer


class CompanyViewSet(viewsets.ModelViewSet):
    """API endpoint para empresas"""
    queryset = Company.objects.all()
    serializer_class = CompanySerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_admin:
            return Company.objects.all()
        elif user.is_employer:
            return Company.objects.filter(admin=user)
        return Company.objects.filter(employees__user=user)
    
    def get_serializer_class(self):
        if self.action == 'list':
            return CompanyListSerializer
        return CompanySerializer
    
    def perform_create(self, serializer):
        # Solo admins y empleadores pueden crear empresas
        if not (self.request.user.is_admin or self.request.user.is_employer):
            raise PermissionDenied("No tienes permiso para crear empresas")
        serializer.save()


class CompanySettingsViewSet(viewsets.ModelViewSet):
    """API endpoint para configuración de empresas"""
    queryset = CompanySettings.objects.all()
    serializer_class = CompanySettingsSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_admin:
            return CompanySettings.objects.all()
        elif user.is_employer:
            return CompanySettings.objects.filter(company__admin=user)
        return CompanySettings.objects.none()


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def company_stats(request, pk):
    """Obtener estadísticas de una empresa"""
    try:
        company = Company.objects.get(pk=pk)
    except Company.DoesNotExist:
        return Response({'error': 'Empresa no encontrada'}, status=status.HTTP_404_NOT_FOUND)
    
    # Verificar permisos
    user = request.user
    if not (user.is_admin or user.is_employer and company.admin == user):
        return Response({'error': 'Sin permisos'}, status=status.HTTP_403_FORBIDDEN)
    
    return Response({
        'total_disbursed': str(company.total_disbursed),
        'total_recovered': str(company.total_recovered),
        'employee_count': company.employee_count,
        'pending_advances': company.advances.filter(status='pending').count(),
        'approved_advances': company.advances.filter(status='approved').count(),
        'disbursed_advances': company.advances.filter(status='disbursed').count(),
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def available_companies(request):
    """Listar empresas disponibles para registro de empleados"""
    companies = Company.objects.filter(is_active=True).values('id', 'name', 'legal_name')
    return Response(list(companies))


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_company(request):
    """Obtener la empresa del usuario empleador actual"""
    user = request.user
    if not user.is_employer:
        return Response({'error': 'Solo disponible para empleadores'}, 
                       status=status.HTTP_403_FORBIDDEN)
    
    try:
        company = Company.objects.get(admin=user)
        serializer = CompanySerializer(company)
        return Response(serializer.data)
    except Company.DoesNotExist:
        return Response({'error': 'No tienes una empresa registrada'}, 
                       status=status.HTTP_404_NOT_FOUND)
