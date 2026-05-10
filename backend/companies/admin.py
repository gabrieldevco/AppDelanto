from django.contrib import admin
from .models import Company, CompanySettings, EmployeeContract, PlatformCapitalMovement


@admin.register(Company)
class CompanyAdmin(admin.ModelAdmin):
    list_display = ['name', 'tax_id', 'admin', 'employee_count', 'is_active', 'is_verified', 'created_at']
    list_filter = ['is_active', 'is_verified', 'created_at']
    search_fields = ['name', 'legal_name', 'tax_id', 'email']
    autocomplete_fields = ['admin']
    
    fieldsets = (
        ('Información básica', {
            'fields': ('name', 'legal_name', 'tax_id')
        }),
        ('Contacto', {
            'fields': ('address', 'phone', 'email')
        }),
        ('Administración', {
            'fields': ('admin',)
        }),
        ('Configuración de adelantos', {
            'fields': ('max_advance_percentage', 'advance_fee_percentage')
        }),
        ('Estado', {
            'fields': ('is_active', 'is_verified')
        }),
    )


@admin.register(CompanySettings)
class CompanySettingsAdmin(admin.ModelAdmin):
    list_display = ['company', 'payment_day', 'min_advance_amount', 'max_advance_amount']
    search_fields = ['company__name']
    autocomplete_fields = ['company']


@admin.register(EmployeeContract)
class EmployeeContractAdmin(admin.ModelAdmin):
    list_display = ['title', 'employee', 'company', 'status', 'signed_at', 'created_at']
    list_filter = ['status', 'created_at', 'signed_at']
    search_fields = ['title', 'employee__user__first_name', 'employee__user__last_name', 'employee__user__email', 'company__name']
    autocomplete_fields = ['company', 'employee', 'uploaded_by']


@admin.register(PlatformCapitalMovement)
class PlatformCapitalMovementAdmin(admin.ModelAdmin):
    list_display = ['created_at', 'movement_type', 'concept', 'amount', 'balance_after', 'actor', 'company']
    list_filter = ['movement_type', 'created_at']
    search_fields = ['concept', 'company__name', 'actor__email', 'actor__first_name', 'actor__last_name']
    raw_id_fields = ['actor', 'company', 'advance']
    readonly_fields = ['created_at']
