from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from rest_framework.parsers import MultiPartParser, FormParser
from django.core.exceptions import ObjectDoesNotExist
from django.db import transaction
from django.db import models
from django.utils import timezone
from decimal import Decimal

from .models import User, EmployeeProfile, AdminProfile
from .serializers import (
    UserSerializer, UserRegistrationSerializer, 
    EmployeeProfileSerializer, AdminProfileSerializer, LoginSerializer,
    UserWithProfileSerializer
)


SUBSCRIPTION_RECEIPT_AMOUNT = Decimal('50000.00')


class UserViewSet(viewsets.ModelViewSet):
    """API endpoint para usuarios"""
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_admin:
            return User.objects.all()
        elif user.is_employer:
            try:
                company = user.company
            except ObjectDoesNotExist:
                return User.objects.filter(id=user.id)
            return User.objects.filter(
                models.Q(id=user.id) | models.Q(employee_profile__company=company)
            )
        return User.objects.filter(id=user.id)


class EmployeeProfileViewSet(viewsets.ModelViewSet):
    """API endpoint para perfiles de empleados"""
    queryset = EmployeeProfile.objects.all()
    serializer_class = EmployeeProfileSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_admin:
            return EmployeeProfile.objects.all()
        elif user.is_employer:
            return EmployeeProfile.objects.filter(company=user.company)
        return EmployeeProfile.objects.filter(user=user)

    def destroy(self, request, *args, **kwargs):
        """Delete the employee profile and its user so the email can be reused."""
        profile = self.get_object()
        employee_user = profile.user
        with transaction.atomic():
            employee_user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['post'], url_path='join-company')
    def join_company(self, request):
        """Permitir que un empleado seleccione su empresa desde el perfil."""
        if not request.user.is_employee:
            return Response(
                {'error': 'Solo los empleados pueden seleccionar empresa'},
                status=status.HTTP_403_FORBIDDEN
            )

        company_id = request.data.get('company_id')
        if not company_id:
            return Response(
                {'company_id': 'Debes seleccionar una empresa'},
                status=status.HTTP_400_BAD_REQUEST
            )

        from companies.models import Company

        try:
            company = Company.objects.get(id=company_id, is_active=True)
        except Company.DoesNotExist:
            return Response(
                {'company_id': 'Empresa no encontrada'},
                status=status.HTTP_404_NOT_FOUND
            )

        profile = request.user.employee_profile
        profile.company = company
        profile.approval_status = 'pending'
        profile.approved_at = None

        bank_name = request.data.get('bank_name')
        bank_account = request.data.get('bank_account')
        if bank_name is not None:
            profile.bank_name = bank_name
        if bank_account is not None:
            profile.bank_account = bank_account

        profile.save(update_fields=['company', 'bank_name', 'bank_account', 'approval_status', 'approved_at'])
        from notifications.models import Notification
        Notification.objects.create(
            user=company.admin,
            type='warning',
            title='Empleado pendiente de aprobacion',
            message=(
                f"{request.user.get_full_name()} solicito vincularse a "
                f"{company.name}. Salario: ${profile.salary}. "
                "Aprueba o deniega su solicitud."
            ),
            link=f'/employee-approvals/{profile.id}'
        )
        return Response(self.get_serializer(profile).data)

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Aprobar la vinculacion de un empleado a la empresa del empleador."""
        profile = self.get_object()
        user = request.user
        if not (user.is_admin or (user.is_employer and profile.company == user.company)):
            return Response({'error': 'No autorizado'}, status=status.HTTP_403_FORBIDDEN)

        profile.approval_status = 'approved'
        profile.approved_at = timezone.now()
        profile.save(update_fields=['approval_status', 'approved_at'])
        self._close_employer_approval_notifications(user, profile, approved=True)
        self._notify_employee(
            profile,
            'Vinculacion aprobada',
            'Tu empleador aprobo tu vinculacion.',
            notification_type='success',
        )
        return Response(self.get_serializer(profile).data)

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Denegar la vinculacion de un empleado a la empresa del empleador."""
        profile = self.get_object()
        user = request.user
        if not (user.is_admin or (user.is_employer and profile.company == user.company)):
            return Response({'error': 'No autorizado'}, status=status.HTTP_403_FORBIDDEN)

        profile.approval_status = 'rejected'
        profile.approved_at = None
        profile.save(update_fields=['approval_status', 'approved_at'])
        self._close_employer_approval_notifications(user, profile, approved=False)
        self._notify_employee(
            profile,
            'Vinculacion denegada',
            'Tu empleador denego tu vinculacion.',
            notification_type='error',
        )
        return Response(self.get_serializer(profile).data)

    def _close_employer_approval_notifications(self, user, profile, approved):
        from notifications.models import Notification

        employee_name = profile.user.get_full_name() or profile.user.email
        company_name = profile.company.name if profile.company else 'la empresa'
        action_text = 'aprobado' if approved else 'denegado'
        message = (
            f"{employee_name} fue {action_text} para vincularse a "
            f"{company_name}. Salario: ${profile.salary}."
        )

        Notification.objects.filter(
            user=user,
            link=f'/employee-approvals/{profile.id}',
        ).update(
            type='success' if approved else 'error',
            title='Empleado aprobado' if approved else 'Empleado denegado',
            message=message,
            link='',
            is_read=True,
            read_at=timezone.now(),
        )

    def _notify_employee(self, profile, title, message, notification_type='info'):
        from notifications.models import Notification
        Notification.objects.create(
            user=profile.user,
            type=notification_type,
            title=title,
            message=message,
        )


class AdminProfileViewSet(viewsets.ModelViewSet):
    """API endpoint para perfiles de administradores"""
    queryset = AdminProfile.objects.all()
    serializer_class = AdminProfileSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        if self.request.user.is_admin:
            return AdminProfile.objects.all()
        return AdminProfile.objects.filter(user=self.request.user)


@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    """Registrar nuevo usuario con soporte para archivos"""
    # Manejar datos multipart (con archivos) o JSON
    data = request.data
    
    serializer = UserRegistrationSerializer(data=data)
    if serializer.is_valid():
        user = serializer.save()
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'user': UserWithProfileSerializer(user, context={'request': request}).data,
            'token': token.key
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    """Iniciar sesión"""
    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.validated_data['user']
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'user': UserWithProfileSerializer(user, context={'request': request}).data,
            'token': token.key
        })
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    """Cerrar sesión"""
    request.user.auth_token.delete()
    return Response({'message': 'Sesión cerrada exitosamente'})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def me(request):
    """Obtener información del usuario actual"""
    user = request.user
    # Usar UserWithProfileSerializer para incluir perfil y empresa
    data = UserWithProfileSerializer(user, context={'request': request}).data
    return Response(data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    """Cambiar contraseña del usuario actual"""
    old_password = request.data.get('old_password')
    new_password = request.data.get('new_password')
    
    if not old_password or not new_password:
        return Response(
            {'error': 'Se requieren old_password y new_password'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    user = request.user
    
    # Verificar contraseña actual
    if not user.check_password(old_password):
        return Response(
            {'error': 'La contraseña actual es incorrecta'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Cambiar contraseña
    user.set_password(new_password)
    user.save()
    
    return Response({'message': 'Contraseña cambiada exitosamente'})


@api_view(['POST'])
@permission_classes([AllowAny])
def password_reset(request):
    """Reset de contraseña por email"""
    email = request.data.get('email')
    
    if not email:
        return Response(
            {'error': 'Se requiere el email'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        user = User.objects.get(email=email)
        # Generar nueva contraseña temporal
        import random
        import string
        temp_password = ''.join(random.choices(string.ascii_letters + string.digits, k=8))
        
        # Actualizar contraseña
        user.set_password(temp_password)
        user.save()
        
        # Aquí debería enviar email con la nueva contraseña
        # Por ahora solo devolvemos la contraseña en desarrollo
        return Response({
            'message': 'Contraseña reseteada exitosamente',
            'temp_password': temp_password  # Solo para desarrollo
        })
        
    except User.DoesNotExist:
        return Response(
            {'error': 'No existe un usuario con ese email'},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_management(request):
    """Vista de gestión de usuarios para administradores"""
    if not request.user.is_admin:
        return Response({'error': 'No autorizado'}, status=status.HTTP_403_FORBIDDEN)
    
    # Obtener todos los usuarios con sus perfiles
    users = User.objects.all().select_related(
        'employee_profile', 'admin_profile', 'company'
    )
    
    role_filter = request.query_params.get('role', None)
    if role_filter:
        users = users.filter(role=role_filter)
    
    search = request.query_params.get('search', None)
    if search:
        users = users.filter(
            models.Q(username__icontains=search) |
            models.Q(email__icontains=search) |
            models.Q(first_name__icontains=search) |
            models.Q(last_name__icontains=search)
        )
    
    serializer = UserWithProfileSerializer(users, many=True, context={'request': request})
    return Response(serializer.data)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def verify_company(request, company_id):
    """Verificar empresa (cambiar is_verified a True)"""
    if not request.user.is_admin:
        return Response({'error': 'No autorizado'}, status=status.HTTP_403_FORBIDDEN)
    
    from companies.models import Company, PlatformCapitalMovement, PlatformSettings
    from companies.serializers import CompanyDetailAdminSerializer
    
    try:
        with transaction.atomic():
            company = Company.objects.select_for_update().get(id=company_id)
            was_verified = company.is_verified
            company.is_verified = True
            company.platform_contract_verified_at = timezone.now()
            company.save(update_fields=['is_verified', 'platform_contract_verified_at', 'updated_at'])

            if not was_verified and company.subscription_fee_credited_at is None:
                settings = PlatformSettings.objects.select_for_update().get(
                    pk=PlatformSettings.get_solo().pk
                )
                settings.initial_capital += SUBSCRIPTION_RECEIPT_AMOUNT
                settings.save(update_fields=['initial_capital', 'updated_at'])
                PlatformCapitalMovement.record(
                    movement_type='entry',
                    concept='Suscripcion de empresa',
                    amount=SUBSCRIPTION_RECEIPT_AMOUNT,
                    balance_after=settings.initial_capital,
                    actor=request.user,
                    company=company,
                    metadata={'source': 'admin_verify_company'},
                )
                company.subscription_fee_credited_at = timezone.now()
                company.save(update_fields=['subscription_fee_credited_at', 'updated_at'])

                from notifications.models import Notification
                Notification.objects.create(
                    user=company.admin,
                    type='success',
                    title='Empresa verificada',
                    message='Felicidades, tu empresa esta verificada.',
                )
        return Response(CompanyDetailAdminSerializer(company, context={'request': request}).data)
    except Company.DoesNotExist:
        return Response({'error': 'Empresa no encontrada'}, status=status.HTTP_404_NOT_FOUND)
