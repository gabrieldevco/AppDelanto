from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.utils import timezone

from .models import Notification, SystemNotification
from .serializers import (
    NotificationSerializer, SystemNotificationSerializer, 
    NotificationMarkReadSerializer
)


class NotificationViewSet(viewsets.ModelViewSet):
    """API endpoint para notificaciones de usuarios"""
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)
    
    @action(detail=False, methods=['post'])
    def mark_read(self, request):
        """Marcar notificaciones como leídas"""
        serializer = NotificationMarkReadSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        mark_all = serializer.validated_data.get('mark_all', False)
        notification_ids = serializer.validated_data.get('notification_ids', [])
        
        if mark_all:
            # Marcar todas las no leídas del usuario
            notifications = self.get_queryset().filter(is_read=False)
            count = notifications.count()
            notifications.update(is_read=True, read_at=timezone.now())
        else:
            # Marcar las especificadas
            notifications = self.get_queryset().filter(
                id__in=notification_ids, 
                is_read=False
            )
            count = notifications.count()
            notifications.update(is_read=True, read_at=timezone.now())
        
        return Response({
            'message': f'{count} notificaciones marcadas como leídas',
            'marked_count': count
        })
    
    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        """Obtener conteo de notificaciones no leídas"""
        count = self.get_queryset().filter(is_read=False).count()
        return Response({'unread_count': count})
    
    def perform_create(self, serializer):
        """Crear notificación para el usuario actual"""
        serializer.save(user=self.request.user)


class SystemNotificationViewSet(viewsets.ReadOnlyModelViewSet):
    """API endpoint para notificaciones del sistema (solo lectura para admins)"""
    queryset = SystemNotification.objects.all()
    serializer_class = SystemNotificationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Solo admins pueden ver notificaciones del sistema"""
        if self.request.user.is_admin:
            return SystemNotification.objects.all()
        return SystemNotification.objects.none()
    
    @action(detail=False, methods=['post'])
    def mark_read(self, request):
        """Marcar todas las notificaciones del sistema como leídas"""
        if not request.user.is_admin:
            return Response({'error': 'Sin permisos'}, status=status.HTTP_403_FORBIDDEN)
        
        count = SystemNotification.objects.filter(is_read=False).count()
        SystemNotification.objects.filter(is_read=False).update(is_read=True)
        
        return Response({
            'message': f'{count} notificaciones del sistema marcadas como leídas',
            'marked_count': count
        })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_notifications(request):
    """Obtener notificaciones del usuario actual (versión simple)"""
    notifications = Notification.objects.filter(user=request.user)
    unread = notifications.filter(is_read=False)
    
    return Response({
        'notifications': NotificationSerializer(notifications[:20], many=True).data,
        'unread_count': unread.count(),
        'total_count': notifications.count()
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_notification_read(request, pk):
    """Marcar una notificación específica como leída"""
    try:
        notification = Notification.objects.get(pk=pk, user=request.user)
    except Notification.DoesNotExist:
        return Response({'error': 'Notificación no encontrada'}, 
                       status=status.HTTP_404_NOT_FOUND)
    
    notification.mark_as_read()
    return Response(NotificationSerializer(notification).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_all_read(request):
    """Marcar todas las notificaciones como leídas"""
    Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
    return Response({'message': 'Todas las notificaciones marcadas como leídas'})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def unread_count(request):
    """Obtener conteo de notificaciones no leídas"""
    count = Notification.objects.filter(user=request.user, is_read=False).count()
    return Response({'unread_count': count})
