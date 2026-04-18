from rest_framework import serializers
from .models import Company, CompanySettings


class CompanySettingsSerializer(serializers.ModelSerializer):
    """Serializer para configuración de empresa"""
    
    class Meta:
        model = CompanySettings
        fields = '__all__'


class CompanySerializer(serializers.ModelSerializer):
    """Serializer para empresa"""
    admin_name = serializers.CharField(source='admin.get_full_name', read_only=True)
    admin_email = serializers.CharField(source='admin.email', read_only=True)
    settings = CompanySettingsSerializer(read_only=True)
    employee_count = serializers.IntegerField(read_only=True)
    chamber_of_commerce_document_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Company
        fields = ['id', 'name', 'legal_name', 'tax_id', 'address', 'phone', 'email',
                  'admin', 'admin_name', 'admin_email', 'max_advance_percentage', 'advance_fee_percentage',
                  'is_active', 'is_verified', 'created_at', 'settings', 'employee_count',
                  'chamber_of_commerce_document', 'chamber_of_commerce_document_url',
                  'bank_account', 'bank_name']
        read_only_fields = ['id', 'created_at', 'is_verified']
    
    def get_chamber_of_commerce_document_url(self, obj):
        """Obtener URL del documento de cámara de comercio"""
        if obj.chamber_of_commerce_document:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.chamber_of_commerce_document.url)
            return obj.chamber_of_commerce_document.url
        return None


class CompanyListSerializer(serializers.ModelSerializer):
    """Serializer simplificado para lista de empresas"""
    
    class Meta:
        model = Company
        fields = ['id', 'name', 'tax_id', 'is_active', 'is_verified', 'employee_count']


class CompanyDetailAdminSerializer(serializers.ModelSerializer):
    """Serializer completo para admin con todos los datos incluyendo documento"""
    admin_name = serializers.CharField(source='admin.get_full_name', read_only=True)
    admin_email = serializers.CharField(source='admin.email', read_only=True)
    admin_phone = serializers.CharField(source='admin.phone', read_only=True)
    admin_document = serializers.CharField(source='admin.document_number', read_only=True)
    settings = CompanySettingsSerializer(read_only=True)
    employee_count = serializers.IntegerField(read_only=True)
    chamber_of_commerce_document_url = serializers.SerializerMethodField()
    has_chamber_document = serializers.SerializerMethodField()
    
    class Meta:
        model = Company
        fields = ['id', 'name', 'legal_name', 'tax_id', 'address', 'phone', 'email',
                  'admin', 'admin_name', 'admin_email', 'admin_phone', 'admin_document',
                  'max_advance_percentage', 'advance_fee_percentage',
                  'is_active', 'is_verified', 'created_at', 'settings', 'employee_count',
                  'chamber_of_commerce_document', 'chamber_of_commerce_document_url', 'has_chamber_document',
                  'bank_account', 'bank_name']
        read_only_fields = ['id', 'created_at']
    
    def get_chamber_of_commerce_document_url(self, obj):
        """Obtener URL del documento de cámara de comercio"""
        if obj.chamber_of_commerce_document:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.chamber_of_commerce_document.url)
            return obj.chamber_of_commerce_document.url
        return None
    
    def get_has_chamber_document(self, obj):
        """Verificar si tiene documento de cámara de comercio"""
        return bool(obj.chamber_of_commerce_document)
