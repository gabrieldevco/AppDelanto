from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from rest_framework.parsers import MultiPartParser, FormParser
from django.db import models

from .models import User, EmployeeProfile, AdminProfile
from .serializers import (
    UserSerializer, UserRegistrationSerializer, 
    EmployeeProfileSerializer, AdminProfileSerializer, LoginSerializer,
    UserWithProfileSerializer
)


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
            return User.objects.filter(employee_profile__company=user.company)
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
            'user': UserSerializer(user).data,
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
    return Response(UserWithProfileSerializer(user, context={'request': request}).data)


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
    
    from companies.models import Company
    from companies.serializers import CompanyDetailAdminSerializer
    
    try:
        company = Company.objects.get(id=company_id)
        company.is_verified = True
        company.save()
        return Response(CompanyDetailAdminSerializer(company, context={'request': request}).data)
    except Company.DoesNotExist:
        return Response({'error': 'Empresa no encontrada'}, status=status.HTTP_404_NOT_FOUND)
