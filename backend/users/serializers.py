from rest_framework import serializers
from .models import User, EmployeeProfile, AdminProfile


class UserSerializer(serializers.ModelSerializer):
    """Serializer para usuario básico"""
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 
                  'role', 'role_display', 'phone', 'document_number', 
                  'is_active', 'created_at']
        read_only_fields = ['id', 'created_at']


class UserRegistrationSerializer(serializers.ModelSerializer):
    """Serializer para registro de usuarios"""
    password = serializers.CharField(write_only=True, min_length=6)
    password_confirm = serializers.CharField(write_only=True)
    
    # Campos adicionales para empleado
    salary = serializers.DecimalField(max_digits=12, decimal_places=2, required=False, allow_null=True)
    
    # Campos adicionales para empleador
    business_name = serializers.CharField(required=False, allow_blank=True)  # Razón social
    company_name = serializers.CharField(required=False, allow_blank=True)   # Nombre comercial
    
    # Campos para información bancaria del empleado
    bank_account = serializers.CharField(required=False, allow_blank=True)
    bank_name = serializers.CharField(required=False, allow_blank=True)
    
    # Campo para empresa (solo empleados)
    company_id = serializers.IntegerField(required=False, allow_null=True)
    
    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password_confirm', 
                  'first_name', 'last_name', 'role', 'phone', 'document_number',
                  'salary', 'business_name', 'company_name', 'bank_account', 'bank_name', 'company_id']
    
    def validate(self, data):
        if data['password'] != data['password_confirm']:
            raise serializers.ValidationError({"password": "Las contraseñas no coinciden"})
        
        role = data.get('role', 'employee')
        
        # Validaciones según rol
        if role == 'employee':
            if not data.get('salary'):
                raise serializers.ValidationError({"salary": "El salario es requerido para empleados"})
            if not data.get('company_id'):
                raise serializers.ValidationError({"company_id": "Debes seleccionar una empresa para registrarte"})
        
        elif role == 'employer':
            if not data.get('business_name'):
                raise serializers.ValidationError({"business_name": "La razón social es requerida para empleadores"})
            if not data.get('company_name'):
                raise serializers.ValidationError({"company_name": "El nombre de la empresa es requerido para empleadores"})
        
        return data
    
    def create(self, validated_data):
        # Extraer campos adicionales
        salary = validated_data.pop('salary', None)
        business_name = validated_data.pop('business_name', '')
        company_name = validated_data.pop('company_name', '')
        bank_account = validated_data.pop('bank_account', '')
        bank_name = validated_data.pop('bank_name', '')
        company_id = validated_data.pop('company_id', None)
        
        validated_data.pop('password_confirm')
        
        # Crear usuario
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            role=validated_data.get('role', 'employee'),
            phone=validated_data.get('phone', ''),
            document_number=validated_data.get('document_number', '')
        )
        
        # Crear perfil según rol
        if user.role == 'employee':
            self._create_employee_profile(user, salary, bank_account, bank_name, company_id)
        elif user.role == 'employer':
            self._create_employer_company(user, business_name, company_name)
        elif user.role == 'admin':
            self._create_admin_profile(user)
        
        return user
    
    def _create_employee_profile(self, user, salary, bank_account='', bank_name='', company_id=None):
        """Crear perfil de empleado"""
        from decimal import Decimal
        from companies.models import Company
        
        salary_decimal = Decimal(str(salary)) if salary else Decimal('0')
        advance_limit = salary_decimal * Decimal('0.5')  # 50% del salario
        
        # Buscar empresa si se proporcionó company_id
        company = None
        if company_id:
            try:
                company = Company.objects.get(id=company_id, is_active=True)
            except Company.DoesNotExist:
                pass
        
        EmployeeProfile.objects.create(
            user=user,
            salary=salary_decimal,
            available_advance_limit=advance_limit,
            bank_account=bank_account or '',
            bank_name=bank_name or '',
            company=company
        )
    
    def _create_employer_company(self, user, business_name, company_name):
        """Crear empresa para empleador"""
        from companies.models import Company, CompanySettings
        
        company = Company.objects.create(
            name=company_name or business_name,
            legal_name=business_name,
            admin=user,
            phone=user.phone or '',
            email=user.email
        )
        
        # Crear configuración por defecto
        CompanySettings.objects.create(company=company)
    
    def _create_admin_profile(self, user):
        """Crear perfil de administrador"""
        AdminProfile.objects.create(user=user)


class EmployeeProfileSerializer(serializers.ModelSerializer):
    """Serializer para perfil de empleado"""
    user = UserSerializer(read_only=True)
    company_name = serializers.CharField(source='company.name', read_only=True)
    
    class Meta:
        model = EmployeeProfile
        fields = ['id', 'user', 'company', 'company_name', 'salary',
                  'available_advance_limit', 'hire_date', 'bank_account', 'bank_name']


class AdminProfileSerializer(serializers.ModelSerializer):
    """Serializer para perfil de administrador"""
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = AdminProfile
        fields = ['id', 'user', 'is_super_admin', 'permissions']


class LoginSerializer(serializers.Serializer):
    """Serializer para login"""
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    
    def validate(self, data):
        from django.contrib.auth import authenticate
        
        try:
            user = User.objects.get(email=data['email'])
        except User.DoesNotExist:
            raise serializers.ValidationError({"email": "Credenciales inválidas"})
        
        user = authenticate(username=user.username, password=data['password'])
        if not user:
            raise serializers.ValidationError({"password": "Credenciales inválidas"})
        
        if not user.is_active:
            raise serializers.ValidationError({"email": "Usuario inactivo"})
        
        data['user'] = user
        return data


class UserWithProfileSerializer(serializers.ModelSerializer):
    """Serializer para usuario con su perfil/empresa completo"""
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    employee_profile = EmployeeProfileSerializer(read_only=True)
    admin_profile = AdminProfileSerializer(read_only=True)
    company = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 
                  'role', 'role_display', 'phone', 'document_number', 
                  'is_active', 'created_at', 'employee_profile', 'admin_profile', 'company']
        read_only_fields = ['id', 'created_at']
    
    def get_company(self, obj):
        """Obtener datos de empresa si es empleador"""
        if obj.role == 'employer' and hasattr(obj, 'company'):
            from companies.serializers import CompanySerializer
            return CompanySerializer(obj.company).data
        return None
