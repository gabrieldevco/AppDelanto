from django.db import models


class Company(models.Model):
    """Empresa/Empleador"""
    
    name = models.CharField(
        max_length=255,
        verbose_name='Nombre de la empresa'
    )
    legal_name = models.CharField(
        max_length=255,
        blank=True,
        verbose_name='Razón social'
    )
    tax_id = models.CharField(
        max_length=50,
        blank=True,
        verbose_name='NIT/RUC'
    )
    address = models.TextField(
        blank=True,
        verbose_name='Dirección'
    )
    phone = models.CharField(
        max_length=20,
        blank=True,
        verbose_name='Teléfono'
    )
    email = models.EmailField(
        blank=True,
        verbose_name='Correo electrónico'
    )
    
    # Administrador de la empresa
    admin = models.OneToOneField(
        'users.User',
        on_delete=models.CASCADE,
        related_name='company',
        limit_choices_to={'role': 'employer'},
        verbose_name='Administrador'
    )
    
    # Cámara de comercio (PDF)
    chamber_of_commerce_document = models.FileField(
        upload_to='chamber_of_commerce/',
        blank=True,
        null=True,
        verbose_name='Cámara de Comercio (PDF)',
        help_text='Documento PDF de cámara de comercio'
    )
    
    # Datos bancarios del empleador
    bank_account = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Cuenta bancaria'
    )
    bank_name = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Banco'
    )
    
    # Configuración de adelantos
    max_advance_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=50.00,
        verbose_name='Porcentaje máximo de adelanto (%)'
    )
    advance_fee_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=2.00,
        verbose_name='Porcentaje de comisión (%)'
    )
    
    # Estado
    is_active = models.BooleanField(
        default=True,
        verbose_name='¿Activa?'
    )
    is_verified = models.BooleanField(
        default=False,
        verbose_name='¿Verificada?'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Empresa'
        verbose_name_plural = 'Empresas'
    
    def __str__(self):
        return self.name
    
    @property
    def employee_count(self):
        return self.employees.count()
    
    @property
    def total_disbursed(self):
        """Total desembolsado a empleados"""
        from advances.models import Advance
        return Advance.objects.filter(
            employee__company=self,
            status='disbursed'
        ).aggregate(
            total=models.Sum('amount')
        )['total'] or 0
    
    @property
    def total_recovered(self):
        """Total recuperado de empleados"""
        from advances.models import Advance
        return Advance.objects.filter(
            employee__company=self,
            status='recovered'
        ).aggregate(
            total=models.Sum('amount')
        )['total'] or 0


class CompanySettings(models.Model):
    """Configuración adicional de la empresa"""
    
    company = models.OneToOneField(
        Company,
        on_delete=models.CASCADE,
        related_name='settings',
        verbose_name='Empresa'
    )
    
    # Configuración de pagos
    payment_day = models.PositiveSmallIntegerField(
        default=15,
        verbose_name='Día de pago',
        help_text='Día del mes en que se realiza el pago de nómina'
    )
    
    # Configuración de notificaciones
    notify_on_advance_request = models.BooleanField(
        default=True,
        verbose_name='Notificar solicitudes de adelanto'
    )
    notify_on_advance_approved = models.BooleanField(
        default=True,
        verbose_name='Notificar aprobaciones'
    )
    
    # Límites
    min_advance_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=50000,
        verbose_name='Monto mínimo de adelanto'
    )
    max_advance_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=1000000,
        verbose_name='Monto máximo de adelanto'
    )
    
    class Meta:
        verbose_name = 'Configuración de Empresa'
        verbose_name_plural = 'Configuraciones de Empresas'
    
    def __str__(self):
        return f"Configuración: {self.company.name}"
