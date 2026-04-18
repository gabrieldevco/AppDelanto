class NotificationModel {
  final int id;
  final int userId;
  final String type;
  final String title;
  final String message;
  final String? link;
  final bool isRead;
  final DateTime? readAt;
  final int? relatedAdvanceId;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.link,
    required this.isRead,
    this.readAt,
    this.relatedAdvanceId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      link: json['link'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      relatedAdvanceId: json['related_advance'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'type': type,
      'title': title,
      'message': message,
      'link': link,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'related_advance': relatedAdvanceId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get typeDisplay {
    switch (type) {
      case 'info':
        return 'Información';
      case 'success':
        return 'Éxito';
      case 'warning':
        return 'Advertencia';
      case 'error':
        return 'Error';
      default:
        return type;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${difference.inDays ~/ 365}a';
    } else if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30}m';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

  NotificationModel copyWith({
    int? id,
    int? userId,
    String? type,
    String? title,
    String? message,
    String? link,
    bool? isRead,
    DateTime? readAt,
    int? relatedAdvanceId,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      link: link ?? this.link,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      relatedAdvanceId: relatedAdvanceId ?? this.relatedAdvanceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SystemNotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  SystemNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory SystemNotificationModel.fromJson(Map<String, dynamic> json) {
    return SystemNotificationModel(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      data: json['data'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get typeDisplay {
    switch (type) {
      case 'new_employer':
        return 'Nuevo Empleador';
      case 'new_employee':
        return 'Nuevo Empleado';
      case 'advance_request':
        return 'Solicitud de Adelanto';
      case 'advance_approved':
        return 'Adelanto Aprobado';
      case 'disbursement':
        return 'Desembolso';
      case 'recovery':
        return 'Recuperación';
      case 'system_alert':
        return 'Alerta del Sistema';
      default:
        return type;
    }
  }
}
