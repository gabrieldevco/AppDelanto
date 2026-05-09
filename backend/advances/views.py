from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from django.utils import timezone
from django.db import models, transaction
from decimal import Decimal

from .models import Advance, AdvanceHistory
from .serializers import (
    AdvanceSerializer, AdvanceCreateSerializer, 
    AdvanceStatusUpdateSerializer, AdvanceListSerializer
)
from notifications.models import Notification
from companies.models import PlatformSettings


def notify_admins_advance_ready(advance):
    """Avisar a administradores que un adelanto aprobado está listo."""
    from users.models import User

    employee_name = advance.employee.user.get_full_name() or advance.employee.user.username
    for admin_user in User.objects.filter(role='admin', is_active=True):
        Notification.objects.get_or_create(
            user=admin_user,
            related_advance=advance,
            title='Adelanto listo para desembolso',
            defaults={
                'type': 'info',
                'message': (
                    f'{employee_name} tiene un adelanto aprobado por '
                    f'${advance.amount:,.0f}'
                ),
            },
        )


class AdvanceViewSet(viewsets.ModelViewSet):
    """API endpoint para adelantos"""
    queryset = Advance.objects.all()
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_admin:
            queryset = Advance.objects.all()
        elif user.is_employer:
            queryset = Advance.objects.filter(company__admin=user)
        else:
            queryset = Advance.objects.filter(employee__user=user)

        return queryset.order_by('-request_date', '-id')
    
    def get_serializer_class(self):
        if self.action == 'create':
            return AdvanceCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return AdvanceStatusUpdateSerializer
        elif self.action == 'list':
            return AdvanceListSerializer
        return AdvanceSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        advance = serializer.instance
        headers = self.get_success_headers(serializer.data)
        return Response(
            AdvanceSerializer(advance, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
            headers=headers,
        )
    
    def perform_create(self, serializer):
        user = self.request.user
        if not user.is_employee:
            raise PermissionDenied("Solo los empleados pueden solicitar adelantos")
        
        employee = user.employee_profile
        if not employee.company:
            raise PermissionDenied("No estás asociado a ninguna empresa")
        
        advance = serializer.save(
            employee=employee,
            company=employee.company
        )
        
        # Crear registro en historial
        AdvanceHistory.objects.create(
            advance=advance,
            status_to='pending',
            changed_by=user,
            notes='Solicitud creada'
        )
        
        # NOTIFICACIÓN: Notificar al empleador (admin de la empresa)
        if employee.company and employee.company.admin:
            Notification.objects.create(
                user=employee.company.admin,
                type='info',
                title='Nueva solicitud de adelanto',
                message=f'{user.get_full_name() or user.username} ha solicitado un adelanto de ${advance.amount:,.0f}',
                related_advance=advance
            )
    
    def perform_update(self, serializer):
        user = self.request.user
        advance = self.get_object()
        old_status = advance.status
        
        # Verificar permisos según el cambio de estado
        new_status = self.request.data.get('status')
        
        if new_status == 'approved':
            if not (user.is_admin or (user.is_employer and advance.company.admin == user)):
                raise PermissionDenied("No tienes permiso para aprobar adelantos")
        elif new_status == 'disbursed':
            if not user.is_admin:
                raise PermissionDenied("Solo los administradores pueden marcar como desembolsado")
        elif new_status == 'recovered':
            if not user.is_admin:
                raise PermissionDenied("Solo los administradores pueden marcar como recuperado")
        
        # Actualizar campos según el estado
        update_data = {}
        if new_status == 'approved':
            update_data['approved_at'] = timezone.now()
            update_data['approved_by'] = user
        elif new_status == 'disbursed':
            update_data['disbursed_at'] = timezone.now()
        
        for key, value in update_data.items():
            setattr(advance, key, value)
        
        advance = serializer.save()
        
        # Crear registro en historial
        notes = self.request.data.get('notes', '')
        AdvanceHistory.objects.create(
            advance=advance,
            status_from=old_status,
            status_to=new_status,
            changed_by=user,
            notes=notes
        )
        
        # NOTIFICACIÓN: Notificar al empleado del cambio de estado
        if new_status == 'approved':
            Notification.objects.create(
                user=advance.employee.user,
                type='success',
                title='Adelanto aprobado',
                message=f'Tu solicitud de adelanto de ${advance.amount:,.0f} ha sido aprobada por {user.get_full_name() or user.username}',
                related_advance=advance
            )
            notify_admins_advance_ready(advance)
        elif new_status == 'rejected':
            Notification.objects.create(
                user=advance.employee.user,
                type='warning',
                title='Adelanto rechazado',
                message=f'Tu solicitud de adelanto de ${advance.amount:,.0f} ha sido rechazada. Motivo: {notes or "Sin especificar"}',
                related_advance=advance
            )
        elif new_status == 'disbursed':
            Notification.objects.create(
                user=advance.employee.user,
                type='success',
                title='Desembolso realizado',
                message=f'El dinero de tu adelanto de ${advance.amount:,.0f} ha sido transferido a tu cuenta bancaria',
                related_advance=advance
            )
        
        # Actualizar límite disponible del empleado si se desembolsa o recupera
        if new_status == 'disbursed':
            advance.employee.available_advance_limit -= advance.amount
            advance.employee.save()
        elif new_status == 'recovered':
            advance.employee.available_advance_limit += advance.amount
            advance.employee.save()


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def advance_stats(request):
    """Obtener estadísticas de adelantos"""
    user = request.user
    
    if user.is_admin:
        queryset = Advance.objects.all()
    elif user.is_employer:
        queryset = Advance.objects.filter(company__admin=user)
    else:
        queryset = Advance.objects.filter(employee__user=user)
    
    return Response({
        'total_requests': queryset.count(),
        'pending': queryset.filter(status='pending').count(),
        'approved': queryset.filter(status='approved').count(),
        'disbursed': queryset.filter(status='disbursed').count(),
        'recovered': queryset.filter(status='recovered').count(),
        'rejected': queryset.filter(status='rejected').count(),
        'total_amount': str(queryset.filter(status__in=['approved', 'disbursed', 'recovered'])
                           .aggregate(total=models.Sum('amount'))['total'] or 0)
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def calculate_advance(request):
    """Calcular fee, interes y total con la configuracion global vigente."""
    from companies.models import FeeRange, PlatformSettings

    if not request.user.is_employee:
        return Response({'error': 'Solo disponible para empleados'}, status=status.HTTP_403_FORBIDDEN)

    amount = Decimal(str(request.data.get('amount', 0)))
    days = int(request.data.get('days', 30))
    settings = PlatformSettings.get_solo()
    FeeRange.ensure_defaults()

    if days < settings.min_days or days > settings.max_days:
        return Response({'error': f'El plazo debe estar entre {settings.min_days} y {settings.max_days} dias'}, status=400)

    fee = FeeRange.fee_for_amount(amount)
    interest = amount * (settings.interest_rate_monthly / Decimal('100')) * (Decimal(days) / Decimal('30'))
    total = amount + fee + interest

    return Response({
        'amount': str(amount),
        'fee': str(fee),
        'interest': str(interest),
        'total': str(total),
        'days': days,
        'interest_rate_monthly': str(settings.interest_rate_monthly),
        'min_days': settings.min_days,
        'max_days': settings.max_days,
        'min_amount': str(FeeRange.objects.order_by('min_amount').first().min_amount),
        'max_amount': str(FeeRange.objects.order_by('-max_amount').first().max_amount),
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def approve_advance(request, pk):
    """Aprobar un adelanto"""
    try:
        advance = Advance.objects.get(pk=pk)
    except Advance.DoesNotExist:
        return Response({'error': 'Adelanto no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    
    user = request.user
    if not (user.is_admin or (user.is_employer and advance.company.admin == user)):
        return Response({'error': 'Sin permisos'}, status=status.HTTP_403_FORBIDDEN)
    if user.is_employer and not advance.company.is_verified:
        return Response(
            {'error': 'Tu empresa debe estar verificada para aprobar adelantos'},
            status=status.HTTP_403_FORBIDDEN,
        )
    
    if advance.status != 'pending':
        return Response({'error': 'Solo se pueden aprobar adelantos pendientes'}, 
                       status=status.HTTP_400_BAD_REQUEST)
    
    old_status = advance.status
    advance.status = 'approved'
    advance.approved_at = timezone.now()
    advance.approved_by = user
    advance.save()
    
    AdvanceHistory.objects.create(
        advance=advance,
        status_from=old_status,
        status_to='approved',
        changed_by=user,
        notes=request.data.get('notes', 'Adelanto aprobado')
    )
    
    # NOTIFICACIÓN: Notificar al empleado que su adelanto fue aprobado
    Notification.objects.create(
        user=advance.employee.user,
        type='success',
        title='Adelanto aprobado',
        message=f'Tu solicitud de adelanto de ${advance.amount:,.0f} ha sido aprobada por {user.get_full_name() or user.username}',
        related_advance=advance
    )

    notify_admins_advance_ready(advance)
    
    return Response(AdvanceSerializer(advance).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def reject_advance(request, pk):
    """Rechazar un adelanto"""
    try:
        advance = Advance.objects.get(pk=pk)
    except Advance.DoesNotExist:
        return Response({'error': 'Adelanto no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    
    user = request.user
    if not (user.is_admin or (user.is_employer and advance.company.admin == user)):
        return Response({'error': 'Sin permisos'}, status=status.HTTP_403_FORBIDDEN)
    if user.is_employer and not advance.company.is_verified:
        return Response(
            {'error': 'Tu empresa debe estar verificada para rechazar adelantos'},
            status=status.HTTP_403_FORBIDDEN,
        )
    
    if advance.status != 'pending':
        return Response({'error': 'Solo se pueden rechazar adelantos pendentes'}, 
                       status=status.HTTP_400_BAD_REQUEST)
    
    old_status = advance.status
    advance.status = 'rejected'
    advance.save()
    
    AdvanceHistory.objects.create(
        advance=advance,
        status_from=old_status,
        status_to='rejected',
        changed_by=user,
        notes=request.data.get('notes', 'Adelanto rechazado')
    )
    
    # NOTIFICACIÓN: Notificar al empleado que su adelanto fue rechazado
    Notification.objects.create(
        user=advance.employee.user,
        type='warning',
        title='Adelanto rechazado',
        message=f'Tu solicitud de adelanto de ${advance.amount:,.0f} ha sido rechazada. Motivo: {request.data.get("notes", "Sin especificar")}',
        related_advance=advance
    )
    
    return Response(AdvanceSerializer(advance).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def pending_advances(request):
    """Obtener adelantos pendientes"""
    user = request.user
    
    if user.is_admin:
        queryset = Advance.objects.filter(status='pending')
    elif user.is_employer:
        queryset = Advance.objects.filter(status='pending', company__admin=user)
    else:
        queryset = Advance.objects.none()
    
    serializer = AdvanceListSerializer(queryset, many=True)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def disburse_advance(request, pk):
    """Marcar un adelanto como desembolsado"""
    try:
        advance = Advance.objects.get(pk=pk)
    except Advance.DoesNotExist:
        return Response({'error': 'Adelanto no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    
    user = request.user
    if not user.is_admin:
        return Response({'error': 'Solo los administradores pueden desembolsar'}, 
                       status=status.HTTP_403_FORBIDDEN)
    
    if advance.status != 'approved':
        return Response({'error': 'Solo se pueden desembolsar adelantos aprobados'}, 
                       status=status.HTTP_400_BAD_REQUEST)
    
    with transaction.atomic():
        settings = PlatformSettings.objects.select_for_update().get(
            pk=PlatformSettings.get_solo().pk
        )
        if settings.initial_capital < advance.amount:
            return Response(
                {'error': 'Capital insuficiente para completar este desembolso'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        old_status = advance.status
        advance.status = 'disbursed'
        advance.disbursed_at = timezone.now()
        advance.disbursement_reference = request.data.get('disbursement_reference', '')
        advance.save()

        settings.initial_capital -= advance.amount
        settings.save(update_fields=['initial_capital', 'updated_at'])

        # Actualizar limite disponible del empleado
        advance.employee.available_advance_limit -= advance.amount
        advance.employee.save()

        AdvanceHistory.objects.create(
            advance=advance,
            status_from=old_status,
            status_to='disbursed',
            changed_by=user,
            notes=request.data.get('notes', 'Adelanto desembolsado')
        )

    Notification.objects.create(
        user=advance.employee.user,
        type='success',
        title='Desembolso realizado',
        message=f'El dinero de tu adelanto de ${advance.amount:,.0f} ha sido transferido a tu cuenta bancaria',
        related_advance=advance
    )
    
    return Response(AdvanceSerializer(advance).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def undisburse_advance(request, pk):
    """Revertir un desembolso marcado por error."""
    try:
        advance = Advance.objects.get(pk=pk)
    except Advance.DoesNotExist:
        return Response({'error': 'Adelanto no encontrado'}, status=status.HTTP_404_NOT_FOUND)

    user = request.user
    if not user.is_admin:
        return Response({'error': 'Solo los administradores pueden revertir desembolsos'},
                       status=status.HTTP_403_FORBIDDEN)

    if advance.status != 'disbursed':
        return Response({'error': 'Solo se pueden marcar como incompletos desembolsos completados'},
                       status=status.HTTP_400_BAD_REQUEST)

    with transaction.atomic():
        old_status = advance.status
        advance.status = 'approved'
        advance.disbursed_at = None
        advance.disbursement_reference = ''
        advance.save()

        settings = PlatformSettings.objects.select_for_update().get(
            pk=PlatformSettings.get_solo().pk
        )
        settings.initial_capital += advance.amount
        settings.save(update_fields=['initial_capital', 'updated_at'])

        advance.employee.available_advance_limit += advance.amount
        advance.employee.save()

        AdvanceHistory.objects.create(
            advance=advance,
            status_from=old_status,
            status_to='approved',
            changed_by=user,
            notes=request.data.get('notes', 'Desembolso marcado como incompleto')
        )

    return Response(AdvanceSerializer(advance).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def recover_advance(request, pk):
    """Marcar un adelanto desembolsado como reembolsado."""
    try:
        advance = Advance.objects.get(pk=pk)
    except Advance.DoesNotExist:
        return Response({'error': 'Adelanto no encontrado'}, status=status.HTTP_404_NOT_FOUND)

    user = request.user
    if not user.is_admin:
        return Response({'error': 'Solo los administradores pueden marcar pagos recibidos'},
                       status=status.HTTP_403_FORBIDDEN)

    if advance.status != 'disbursed':
        return Response({'error': 'Solo se pueden reembolsar adelantos desembolsados'},
                       status=status.HTTP_400_BAD_REQUEST)

    with transaction.atomic():
        settings = PlatformSettings.objects.select_for_update().get(
            pk=PlatformSettings.get_solo().pk
        )

        old_status = advance.status
        advance.status = 'recovered'
        advance.recovery_date = timezone.localdate()
        advance.save()

        settings.initial_capital += advance.total_amount
        settings.save(update_fields=['initial_capital', 'updated_at'])

        advance.employee.available_advance_limit += advance.amount
        advance.employee.save()

        AdvanceHistory.objects.create(
            advance=advance,
            status_from=old_status,
            status_to='recovered',
            changed_by=user,
            notes=request.data.get('notes', 'Pago recibido marcado como reembolsado')
        )

    Notification.objects.create(
        user=advance.employee.user,
        type='success',
        title='Pago recibido',
        message=f'Tu adelanto de ${advance.amount:,.0f} fue marcado como reembolsado',
        related_advance=advance
    )

    return Response(AdvanceSerializer(advance).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def unrecover_advance(request, pk):
    """Deshacer un reembolso marcado por error."""
    try:
        advance = Advance.objects.get(pk=pk)
    except Advance.DoesNotExist:
        return Response({'error': 'Adelanto no encontrado'}, status=status.HTTP_404_NOT_FOUND)

    user = request.user
    if not user.is_admin:
        return Response({'error': 'Solo los administradores pueden deshacer reembolsos'},
                       status=status.HTTP_403_FORBIDDEN)

    if advance.status != 'recovered':
        return Response({'error': 'Solo se pueden deshacer pagos recibidos reembolsados'},
                       status=status.HTTP_400_BAD_REQUEST)

    with transaction.atomic():
        settings = PlatformSettings.objects.select_for_update().get(
            pk=PlatformSettings.get_solo().pk
        )
        if settings.initial_capital < advance.total_amount:
            return Response(
                {'error': 'Capital insuficiente para deshacer este reembolso'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        old_status = advance.status
        advance.status = 'disbursed'
        advance.recovery_date = None
        advance.save()

        settings.initial_capital -= advance.total_amount
        settings.save(update_fields=['initial_capital', 'updated_at'])

        advance.employee.available_advance_limit -= advance.amount
        advance.employee.save()

        AdvanceHistory.objects.create(
            advance=advance,
            status_from=old_status,
            status_to='disbursed',
            changed_by=user,
            notes=request.data.get('notes', 'Reembolso deshecho')
        )

    return Response(AdvanceSerializer(advance).data)
