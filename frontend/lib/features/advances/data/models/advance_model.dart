class AdvanceModel {
  final int id;
  final int employeeId;
  final String employeeName;
  final int companyId;
  final String companyName;
  final double amount;
  final double fee;
  final double totalAmount;
  final String status;
  final String? reason;
  final DateTime requestDate;
  final DateTime? approvedAt;
  final DateTime? disbursedAt;
  final DateTime? recoveryDate;
  final String? approvedByName;
  final String? disbursementReference;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdvanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.companyId,
    required this.companyName,
    required this.amount,
    required this.fee,
    required this.totalAmount,
    required this.status,
    this.reason,
    required this.requestDate,
    this.approvedAt,
    this.disbursedAt,
    this.recoveryDate,
    this.approvedByName,
    this.disbursementReference,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdvanceModel.fromJson(Map<String, dynamic> json) {
    return AdvanceModel(
      id: json['id'],
      employeeId: json['employee'],
      employeeName: json['employee_name'] ?? 'Desconocido',
      companyId: json['company'],
      companyName: json['company_name'] ?? 'Desconocida',
      amount: double.parse(json['amount'].toString()),
      fee: double.parse(json['fee'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      status: json['status'],
      reason: json['reason'],
      requestDate: DateTime.parse(json['request_date']),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      disbursedAt: json['disbursed_at'] != null
          ? DateTime.parse(json['disbursed_at'])
          : null,
      recoveryDate: json['recovery_date'] != null
          ? DateTime.parse(json['recovery_date'])
          : null,
      approvedByName: json['approved_by_name'],
      disbursementReference: json['disbursement_reference'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee': employeeId,
      'employee_name': employeeName,
      'company': companyId,
      'company_name': companyName,
      'amount': amount,
      'fee': fee,
      'total_amount': totalAmount,
      'status': status,
      'reason': reason,
      'request_date': requestDate.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'disbursed_at': disbursedAt?.toIso8601String(),
      'recovery_date': recoveryDate?.toIso8601String(),
      'approved_by_name': approvedByName,
      'disbursement_reference': disbursementReference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isDisbursed => status == 'disbursed';
  bool get isRecovered => status == 'recovered';
  bool get isCancelled => status == 'cancelled';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      case 'disbursed':
        return 'Desembolsado';
      case 'recovered':
        return 'Recuperado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  AdvanceModel copyWith({
    int? id,
    int? employeeId,
    String? employeeName,
    int? companyId,
    String? companyName,
    double? amount,
    double? fee,
    double? totalAmount,
    String? status,
    String? reason,
    DateTime? requestDate,
    DateTime? approvedAt,
    DateTime? disbursedAt,
    DateTime? recoveryDate,
    String? approvedByName,
    String? disbursementReference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdvanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      requestDate: requestDate ?? this.requestDate,
      approvedAt: approvedAt ?? this.approvedAt,
      disbursedAt: disbursedAt ?? this.disbursedAt,
      recoveryDate: recoveryDate ?? this.recoveryDate,
      approvedByName: approvedByName ?? this.approvedByName,
      disbursementReference: disbursementReference ?? this.disbursementReference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
