from rest_framework import serializers
from .models import Company, CompanySettings, EmployeeContract


class CompanySettingsSerializer(serializers.ModelSerializer):
    """Serializer para configuracion de empresa"""

    class Meta:
        model = CompanySettings
        fields = '__all__'


class CompanyDocumentMixin:
    document_url_fields = [
        'rut_document',
        'chamber_of_commerce_document',
        'legal_representative_id_document',
        'bank_statements_document',
        'platform_contract_file',
        'subscription_receipt_file',
    ]

    def _file_url(self, file_field):
        if file_field:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(file_field.url)
            return file_field.url
        return None

    def get_rut_document_url(self, obj):
        return self._file_url(obj.rut_document)

    def get_chamber_of_commerce_document_url(self, obj):
        return self._file_url(obj.chamber_of_commerce_document)

    def get_legal_representative_id_document_url(self, obj):
        return self._file_url(obj.legal_representative_id_document)

    def get_bank_statements_document_url(self, obj):
        return self._file_url(obj.bank_statements_document)

    def get_platform_contract_file_url(self, obj):
        return self._file_url(obj.platform_contract_file)

    def get_subscription_receipt_file_url(self, obj):
        return self._file_url(obj.subscription_receipt_file)


class CompanySerializer(CompanyDocumentMixin, serializers.ModelSerializer):
    """Serializer para empresa"""
    admin_name = serializers.CharField(source='admin.get_full_name', read_only=True)
    admin_email = serializers.CharField(source='admin.email', read_only=True)
    settings = CompanySettingsSerializer(read_only=True)
    employee_count = serializers.IntegerField(read_only=True)
    rut_document_url = serializers.SerializerMethodField()
    chamber_of_commerce_document_url = serializers.SerializerMethodField()
    legal_representative_id_document_url = serializers.SerializerMethodField()
    bank_statements_document_url = serializers.SerializerMethodField()
    platform_contract_file_url = serializers.SerializerMethodField()
    subscription_receipt_file_url = serializers.SerializerMethodField()

    class Meta:
        model = Company
        fields = [
            'id', 'name', 'legal_name', 'tax_id', 'address', 'city', 'phone', 'email',
            'admin', 'admin_name', 'admin_email', 'max_advance_percentage',
            'advance_fee_percentage', 'is_active', 'is_verified', 'is_preapproved',
            'created_at', 'settings', 'employee_count',
            'rut_document', 'rut_document_url',
            'chamber_of_commerce_document', 'chamber_of_commerce_document_url',
            'legal_representative_id_document',
            'legal_representative_id_document_url',
            'bank_statements_document', 'bank_statements_document_url',
            'bank_account', 'bank_name', 'platform_contract_file',
            'platform_contract_file_url', 'platform_contract_uploaded_at',
            'platform_contract_verified_at',
            'subscription_receipt_file', 'subscription_receipt_file_url',
            'subscription_receipt_uploaded_at',
        ]
        read_only_fields = ['id', 'created_at', 'is_verified']


class CompanyListSerializer(serializers.ModelSerializer):
    """Serializer simplificado para lista de empresas"""

    class Meta:
        model = Company
        fields = ['id', 'name', 'tax_id', 'is_active', 'is_verified', 'is_preapproved', 'employee_count']


class CompanyDetailAdminSerializer(CompanyDocumentMixin, serializers.ModelSerializer):
    """Serializer completo para admin con todos los datos incluyendo documentos"""
    admin_name = serializers.CharField(source='admin.get_full_name', read_only=True)
    admin_email = serializers.CharField(source='admin.email', read_only=True)
    admin_phone = serializers.CharField(source='admin.phone', read_only=True)
    admin_document = serializers.CharField(source='admin.document_number', read_only=True)
    settings = CompanySettingsSerializer(read_only=True)
    employee_count = serializers.IntegerField(read_only=True)
    rut_document_url = serializers.SerializerMethodField()
    chamber_of_commerce_document_url = serializers.SerializerMethodField()
    legal_representative_id_document_url = serializers.SerializerMethodField()
    bank_statements_document_url = serializers.SerializerMethodField()
    platform_contract_file_url = serializers.SerializerMethodField()
    subscription_receipt_file_url = serializers.SerializerMethodField()
    has_chamber_document = serializers.SerializerMethodField()

    class Meta:
        model = Company
        fields = [
            'id', 'name', 'legal_name', 'tax_id', 'address', 'city', 'phone', 'email',
            'admin', 'admin_name', 'admin_email', 'admin_phone',
            'admin_document', 'max_advance_percentage',
            'advance_fee_percentage', 'is_active', 'is_verified', 'is_preapproved',
            'created_at', 'settings', 'employee_count',
            'rut_document', 'rut_document_url',
            'chamber_of_commerce_document', 'chamber_of_commerce_document_url',
            'has_chamber_document', 'legal_representative_id_document',
            'legal_representative_id_document_url',
            'bank_statements_document', 'bank_statements_document_url',
            'bank_account', 'bank_name', 'platform_contract_file',
            'platform_contract_file_url', 'platform_contract_uploaded_at',
            'platform_contract_verified_at',
            'subscription_receipt_file', 'subscription_receipt_file_url',
            'subscription_receipt_uploaded_at',
        ]
        read_only_fields = ['id', 'created_at']

    def get_has_chamber_document(self, obj):
        return bool(obj.chamber_of_commerce_document)


class EmployeeContractSerializer(serializers.ModelSerializer):
    employee_name = serializers.CharField(source='employee.user.get_full_name', read_only=True)
    employee_email = serializers.CharField(source='employee.user.email', read_only=True)
    company_name = serializers.CharField(source='company.name', read_only=True)
    contract_file_url = serializers.SerializerMethodField()
    signature_image_url = serializers.SerializerMethodField()

    class Meta:
        model = EmployeeContract
        fields = [
            'id', 'title', 'company', 'company_name', 'employee',
            'employee_name', 'employee_email', 'contract_file',
            'contract_file_url', 'status', 'signature_image',
            'signature_image_url', 'signed_at', 'signer_ip',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'company', 'company_name', 'employee_name',
            'employee_email', 'status', 'signature_image', 'signed_at',
            'signer_ip', 'created_at', 'updated_at',
        ]

    def _file_url(self, file_field):
        if file_field:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(file_field.url)
            return file_field.url
        return None

    def get_contract_file_url(self, obj):
        return self._file_url(obj.contract_file)

    def get_signature_image_url(self, obj):
        return self._file_url(obj.signature_image)
