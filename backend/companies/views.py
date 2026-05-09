from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from django.core.mail import send_mail
from django.db import transaction
from django.utils import timezone
from decimal import Decimal

from .models import Company, CompanySettings, EmployeeContract, PlatformSettings
from .serializers import (
    CompanySerializer,
    CompanyListSerializer,
    CompanySettingsSerializer,
    EmployeeContractSerializer,
)
from users.models import User, EmployeeProfile
from users.serializers import EmployeeProfileSerializer


SUBSCRIPTION_RECEIPT_AMOUNT = Decimal('50000.00')


def _notify_company_verified(company):
    from notifications.models import Notification

    if company.admin_id:
        Notification.objects.create(
            user=company.admin,
            type='success',
            title='Empresa verificada',
            message='Felicidades, tu empresa esta verificada.',
        )


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

    @action(detail=True, methods=['post'])
    def employees(self, request, pk=None):
        """Crear un empleado desde el modulo del empleador."""
        company = self.get_object()
        user = request.user
        if not (user.is_admin or (user.is_employer and company.admin == user)):
            return Response({'error': 'Sin permisos'}, status=status.HTTP_403_FORBIDDEN)
        if user.is_employer and not company.is_verified:
            return Response(
                {'error': 'Tu empresa debe estar verificada para crear empleados'},
                status=status.HTTP_403_FORBIDDEN,
            )

        required_fields = ['email', 'password', 'first_name', 'salary']
        missing = [field for field in required_fields if not request.data.get(field)]
        if missing:
            return Response(
                {'error': f'Campos requeridos: {", ".join(missing)}'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        email = request.data.get('email', '').strip().lower()
        username = request.data.get('username') or email.split('@')[0]
        username = username.strip().lower()
        existing_user = User.objects.filter(email=email).first()
        if existing_user and not hasattr(existing_user, 'employee_profile'):
            existing_user.delete()
        elif existing_user:
            return Response(
                {'email': 'Ya existe un usuario con este correo'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        base_username = username
        suffix = 1
        while User.objects.filter(username=username).exists():
            username = f'{base_username}.{company.id}.{suffix}'
            suffix += 1

        try:
            salary = Decimal(str(request.data.get('salary')))
        except Exception:
            return Response(
                {'salary': 'El salario no es valido'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        password = request.data.get('password')
        hire_date = request.data.get('hire_date') or None
        if isinstance(hire_date, str) and 'T' in hire_date:
            hire_date = hire_date.split('T', 1)[0]
        with transaction.atomic():
            employee_user = User.objects.create_user(
                username=username,
                email=email,
                password=password,
                first_name=request.data.get('first_name', '').strip(),
                last_name=request.data.get('last_name', '').strip(),
                role='employee',
                phone=request.data.get('phone', '') or '',
                document_number=request.data.get('document_number', '') or '',
            )
            profile = EmployeeProfile.objects.create(
                user=employee_user,
                company=company,
                salary=salary,
                available_advance_limit=salary * Decimal('0.5'),
                bank_account=request.data.get('bank_account', '') or '',
                bank_name=request.data.get('bank_name', '') or '',
                hire_date=hire_date,
                approval_status='approved',
                approved_at=timezone.now(),
            )
            contract_file = request.FILES.get('contract_file')
            if contract_file:
                EmployeeContract.objects.create(
                    company=company,
                    employee=profile,
                    uploaded_by=user,
                    title=request.data.get('contract_title') or 'Contrato Appdelanta',
                    contract_file=contract_file,
                )

        send_mail(
            subject='Credenciales de acceso a AppDelanta',
            message=(
                f'Hola {employee_user.get_full_name()},\n\n'
                f'{company.name} creo tu usuario en AppDelanta.\n'
                f'Correo: {employee_user.email}\n'
                f'Contrasena temporal: {password}\n\n'
                'Ingresa a la app y cambia tu contrasena desde tu perfil.'
            ),
            from_email=None,
            recipient_list=[employee_user.email],
            fail_silently=True,
        )

        serializer = EmployeeProfileSerializer(profile, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['patch'])
    def verify(self, request, pk=None):
        """Verificar o remover verificación de una empresa."""
        if not request.user.is_admin:
            return Response({'error': 'No autorizado'}, status=status.HTTP_403_FORBIDDEN)

        company = self.get_object()
        raw_is_verified = request.data.get('is_verified', True)
        if isinstance(raw_is_verified, str):
            is_verified = raw_is_verified.strip().lower() in ('true', '1', 'yes', 'si', 's')
        else:
            is_verified = bool(raw_is_verified)

        with transaction.atomic():
            company = Company.objects.select_for_update().get(pk=company.pk)
            was_verified = company.is_verified
            company.is_verified = is_verified
            if company.is_verified:
                company.platform_contract_verified_at = timezone.now()
            else:
                company.platform_contract_verified_at = None
            company.save(update_fields=['is_verified', 'platform_contract_verified_at', 'updated_at'])

            if (
                company.is_verified
                and not was_verified
                and company.subscription_fee_credited_at is None
            ):
                # Verificar empresa: sumar 50000 al capital
                settings = PlatformSettings.objects.select_for_update().get(
                    pk=PlatformSettings.get_solo().pk
                )
                settings.initial_capital += SUBSCRIPTION_RECEIPT_AMOUNT
                settings.save(update_fields=['initial_capital', 'updated_at'])
                company.subscription_fee_credited_at = timezone.now()
                company.save(update_fields=['subscription_fee_credited_at', 'updated_at'])
                _notify_company_verified(company)
            elif (
                not company.is_verified
                and was_verified
                and company.subscription_fee_credited_at is not None
            ):
                # Desverificar empresa: NO restar del capital, solo limpiar la marca
                # para que al volver a verificar se sumen otros 50000
                company.subscription_fee_credited_at = None
                company.save(update_fields=['subscription_fee_credited_at', 'updated_at'])

        serializer = self.get_serializer(company)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def preapprove(self, request, pk=None):
        """Preaprobar empresa para que el empleador pueda entrar y subir contrato."""
        if not request.user.is_admin:
            return Response({'error': 'No autorizado'}, status=status.HTTP_403_FORBIDDEN)

        company = self.get_object()
        company.is_preapproved = True
        company.is_verified = False
        company.save(update_fields=['is_preapproved', 'is_verified', 'updated_at'])
        from notifications.models import Notification
        Notification.objects.create(
            user=company.admin,
            type='info',
            title='Empresa preaprobada',
            message='Tu empresa fue preaprobada. Ingresa para descargar y adjuntar el contrato firmado.',
        )
        serializer = self.get_serializer(company)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def upload_subscription_receipt(self, request, pk=None):
        company = self.get_object()
        user = request.user
        if not (user.is_admin or (user.is_employer and company.admin == user)):
            return Response({'error': 'Sin permisos'}, status=status.HTTP_403_FORBIDDEN)
        if not company.is_preapproved and not user.is_admin:
            return Response({'error': 'La empresa aun no esta preaprobada'}, status=status.HTTP_400_BAD_REQUEST)

        receipt_file = request.FILES.get('subscription_receipt_file')
        if not receipt_file:
            return Response({'subscription_receipt_file': 'El volante es requerido'}, status=status.HTTP_400_BAD_REQUEST)

        file_name = receipt_file.name.lower()
        allowed_extensions = ('.pdf', '.png', '.jpg', '.jpeg')
        if not file_name.endswith(allowed_extensions):
            return Response(
                {'subscription_receipt_file': 'Solo se permite PDF, PNG, JPG o JPEG'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        company.subscription_receipt_file = receipt_file
        company.subscription_receipt_uploaded_at = timezone.now()
        company.save(update_fields=[
            'subscription_receipt_file',
            'subscription_receipt_uploaded_at',
            'updated_at',
        ])

        from notifications.models import Notification
        admins = User.objects.filter(role='admin', is_active=True)
        for admin in admins:
            Notification.objects.create(
                user=admin,
                type='warning',
                title='Volante de suscripcion adjuntado',
                message=f'La empresa {company.name} adjunto su volante de suscripcion para revision.',
            )
        serializer = self.get_serializer(company)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def upload_platform_contract(self, request, pk=None):
        company = self.get_object()
        user = request.user
        if not (user.is_admin or (user.is_employer and company.admin == user)):
            return Response({'error': 'Sin permisos'}, status=status.HTTP_403_FORBIDDEN)
        if not company.is_preapproved and not user.is_admin:
            return Response({'error': 'La empresa aun no esta preaprobada'}, status=status.HTTP_400_BAD_REQUEST)

        contract_file = request.FILES.get('platform_contract_file')
        if not contract_file:
            return Response({'platform_contract_file': 'El PDF firmado es requerido'}, status=status.HTTP_400_BAD_REQUEST)
        if not contract_file.name.lower().endswith('.pdf'):
            return Response({'platform_contract_file': 'Solo se permite PDF'}, status=status.HTTP_400_BAD_REQUEST)

        company.platform_contract_file = contract_file
        company.platform_contract_uploaded_at = timezone.now()
        company.platform_contract_verified_at = None
        company.is_verified = False
        company.save(update_fields=[
            'platform_contract_file', 'platform_contract_uploaded_at',
            'platform_contract_verified_at', 'is_verified', 'updated_at',
        ])

        from notifications.models import Notification
        admins = User.objects.filter(role='admin', is_active=True)
        for admin in admins:
            Notification.objects.create(
                user=admin,
                type='warning',
                title='Contrato firmado adjuntado',
                message=f'Contrato de la empresa {company.name} adjuntado y firmado para su verificacion.',
            )
        serializer = self.get_serializer(company)
        return Response(serializer.data)


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


class EmployeeContractViewSet(viewsets.ModelViewSet):
    serializer_class = EmployeeContractSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_queryset(self):
        user = self.request.user
        queryset = EmployeeContract.objects.select_related(
            'company', 'employee__user', 'uploaded_by',
        )
        if user.is_admin:
            return queryset
        if user.is_employer:
            return queryset.filter(company__admin=user)
        if user.is_employee:
            return queryset.filter(employee__user=user)
        return queryset.none()

    def perform_create(self, serializer):
        user = self.request.user
        if not (user.is_admin or user.is_employer):
            raise PermissionDenied('Solo empleadores o administradores pueden subir contratos')

        employee = serializer.validated_data['employee']
        company = employee.company
        if company is None:
            raise PermissionDenied('El empleado no esta vinculado a una empresa')
        if user.is_employer and company.admin != user:
            raise PermissionDenied('No puedes subir contratos para este empleado')

        serializer.save(company=company, uploaded_by=user)

    @action(detail=True, methods=['post'])
    def sign(self, request, pk=None):
        contract = self.get_object()
        user = request.user
        if not (user.is_employee and contract.employee.user == user):
            return Response({'error': 'Solo el empleado asignado puede firmar'}, status=status.HTTP_403_FORBIDDEN)
        if contract.status == 'signed':
            return Response({'error': 'El contrato ya fue firmado'}, status=status.HTTP_400_BAD_REQUEST)

        signature_image = request.FILES.get('signature_image')
        if not signature_image:
            return Response({'signature_image': 'La firma es requerida'}, status=status.HTTP_400_BAD_REQUEST)

        forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        signer_ip = forwarded_for.split(',')[0].strip() if forwarded_for else request.META.get('REMOTE_ADDR')
        contract.signature_image = signature_image
        contract.status = 'signed'
        contract.signed_at = timezone.now()
        contract.signer_ip = signer_ip
        contract.save(update_fields=['signature_image', 'status', 'signed_at', 'signer_ip', 'updated_at'])

        serializer = self.get_serializer(contract)
        return Response(serializer.data)


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
        serializer = CompanySerializer(company, context={'request': request})
        return Response(serializer.data)
    except Company.DoesNotExist:
        return Response({'error': 'No tienes una empresa registrada'}, 
                       status=status.HTTP_404_NOT_FOUND)
