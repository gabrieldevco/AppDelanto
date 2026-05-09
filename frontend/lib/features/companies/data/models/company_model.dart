class CompanyModel {
  final int id;
  final String name;
  final String? legalName;
  final String? taxId;
  final String? address;
  final String? city;
  final String? phone;
  final String? email;
  final int? adminId;
  final String? adminName;
  final double maxAdvancePercentage;
  final double advanceFeePercentage;
  final bool isActive;
  final bool isVerified;
  final bool isPreapproved;
  final String? platformContractFileUrl;
  final DateTime? platformContractUploadedAt;
  final String? subscriptionReceiptFileUrl;
  final DateTime? subscriptionReceiptUploadedAt;
  final int employeeCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CompanySettings? settings;
  final String? bankAccount;
  final String? bankName;

  CompanyModel({
    required this.id,
    required this.name,
    this.legalName,
    this.taxId,
    this.address,
    this.city,
    this.phone,
    this.email,
    this.adminId,
    this.adminName,
    required this.maxAdvancePercentage,
    required this.advanceFeePercentage,
    required this.isActive,
    required this.isVerified,
    this.isPreapproved = false,
    this.platformContractFileUrl,
    this.platformContractUploadedAt,
    this.subscriptionReceiptFileUrl,
    this.subscriptionReceiptUploadedAt,
    this.employeeCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.settings,
    this.bankAccount,
    this.bankName,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(
      (json['created_at'] ?? DateTime.now().toIso8601String()).toString(),
    );
    return CompanyModel(
      id: json['id'],
      name: json['name'],
      legalName: json['legal_name'],
      taxId: json['tax_id'],
      address: json['address'],
      city: json['city'],
      phone: json['phone'],
      email: json['email'],
      adminId: json['admin'],
      adminName: json['admin_name'],
      maxAdvancePercentage: double.parse(
        json['max_advance_percentage'].toString(),
      ),
      advanceFeePercentage: double.parse(
        json['advance_fee_percentage'].toString(),
      ),
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      isPreapproved: json['is_preapproved'] ?? false,
      platformContractFileUrl:
          json['platform_contract_file_url'] ?? json['platform_contract_file'],
      platformContractUploadedAt: json['platform_contract_uploaded_at'] != null
          ? DateTime.tryParse(json['platform_contract_uploaded_at'])
          : null,
      subscriptionReceiptFileUrl:
          json['subscription_receipt_file_url'] ??
          json['subscription_receipt_file'],
      subscriptionReceiptUploadedAt:
          json['subscription_receipt_uploaded_at'] != null
          ? DateTime.tryParse(json['subscription_receipt_uploaded_at'])
          : null,
      employeeCount: json['employee_count'] ?? 0,
      createdAt: createdAt,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : createdAt,
      settings: json['settings'] != null
          ? CompanySettings.fromJson(json['settings'])
          : null,
      bankAccount: json['bank_account'],
      bankName: json['bank_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'legal_name': legalName,
      'tax_id': taxId,
      'address': address,
      'city': city,
      'phone': phone,
      'email': email,
      'admin': adminId,
      'admin_name': adminName,
      'max_advance_percentage': maxAdvancePercentage,
      'advance_fee_percentage': advanceFeePercentage,
      'is_active': isActive,
      'is_verified': isVerified,
      'is_preapproved': isPreapproved,
      'platform_contract_file_url': platformContractFileUrl,
      'platform_contract_uploaded_at': platformContractUploadedAt
          ?.toIso8601String(),
      'subscription_receipt_file_url': subscriptionReceiptFileUrl,
      'subscription_receipt_uploaded_at': subscriptionReceiptUploadedAt
          ?.toIso8601String(),
      'employee_count': employeeCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'settings': settings?.toJson(),
      'bank_account': bankAccount,
      'bank_name': bankName,
    };
  }

  double get maxAdvanceAmount => employeeCount > 0 ? maxAdvancePercentage : 0;

  CompanyModel copyWith({
    int? id,
    String? name,
    String? legalName,
    String? taxId,
    String? address,
    String? city,
    String? phone,
    String? email,
    int? adminId,
    String? adminName,
    double? maxAdvancePercentage,
    double? advanceFeePercentage,
    bool? isActive,
    bool? isVerified,
    bool? isPreapproved,
    String? platformContractFileUrl,
    DateTime? platformContractUploadedAt,
    String? subscriptionReceiptFileUrl,
    DateTime? subscriptionReceiptUploadedAt,
    int? employeeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    CompanySettings? settings,
    String? bankAccount,
    String? bankName,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      maxAdvancePercentage: maxAdvancePercentage ?? this.maxAdvancePercentage,
      advanceFeePercentage: advanceFeePercentage ?? this.advanceFeePercentage,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      isPreapproved: isPreapproved ?? this.isPreapproved,
      platformContractFileUrl:
          platformContractFileUrl ?? this.platformContractFileUrl,
      platformContractUploadedAt:
          platformContractUploadedAt ?? this.platformContractUploadedAt,
      subscriptionReceiptFileUrl:
          subscriptionReceiptFileUrl ?? this.subscriptionReceiptFileUrl,
      subscriptionReceiptUploadedAt:
          subscriptionReceiptUploadedAt ?? this.subscriptionReceiptUploadedAt,
      employeeCount: employeeCount ?? this.employeeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
      bankAccount: bankAccount ?? this.bankAccount,
      bankName: bankName ?? this.bankName,
    );
  }
}

class CompanySettings {
  final int id;
  final int paymentDay;
  final bool notifyOnAdvanceRequest;
  final bool notifyOnAdvanceApproved;
  final double minAdvanceAmount;
  final double maxAdvanceAmount;

  CompanySettings({
    required this.id,
    required this.paymentDay,
    required this.notifyOnAdvanceRequest,
    required this.notifyOnAdvanceApproved,
    required this.minAdvanceAmount,
    required this.maxAdvanceAmount,
  });

  factory CompanySettings.fromJson(Map<String, dynamic> json) {
    return CompanySettings(
      id: json['id'],
      paymentDay: json['payment_day'] ?? 15,
      notifyOnAdvanceRequest: json['notify_on_advance_request'] ?? true,
      notifyOnAdvanceApproved: json['notify_on_advance_approved'] ?? true,
      minAdvanceAmount: double.parse(json['min_advance_amount'].toString()),
      maxAdvanceAmount: double.parse(json['max_advance_amount'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_day': paymentDay,
      'notify_on_advance_request': notifyOnAdvanceRequest,
      'notify_on_advance_approved': notifyOnAdvanceApproved,
      'min_advance_amount': minAdvanceAmount,
      'max_advance_amount': maxAdvanceAmount,
    };
  }

  CompanySettings copyWith({
    int? id,
    int? paymentDay,
    bool? notifyOnAdvanceRequest,
    bool? notifyOnAdvanceApproved,
    double? minAdvanceAmount,
    double? maxAdvanceAmount,
  }) {
    return CompanySettings(
      id: id ?? this.id,
      paymentDay: paymentDay ?? this.paymentDay,
      notifyOnAdvanceRequest:
          notifyOnAdvanceRequest ?? this.notifyOnAdvanceRequest,
      notifyOnAdvanceApproved:
          notifyOnAdvanceApproved ?? this.notifyOnAdvanceApproved,
      minAdvanceAmount: minAdvanceAmount ?? this.minAdvanceAmount,
      maxAdvanceAmount: maxAdvanceAmount ?? this.maxAdvanceAmount,
    );
  }
}

class EmployeeModel {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String? phone;
  final double salary;
  final double availableAdvanceLimit;
  final DateTime? hireDate;
  final String? bankAccount;
  final String? bankName;
  final bool isActive;
  final String? documentNumber;

  EmployeeModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.salary,
    required this.availableAdvanceLimit,
    this.hireDate,
    this.bankAccount,
    this.bankName,
    required this.isActive,
    this.documentNumber,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    final firstName = (user['first_name'] ?? '').toString().trim();
    final lastName = (user['last_name'] ?? '').toString().trim();
    final fullName = '$firstName $lastName'.trim();
    return EmployeeModel(
      id: json['id'],
      userId: json['user_id'] ?? user['id'] ?? 0,
      name: json['name'] ?? (fullName.isEmpty ? 'Sin nombre' : fullName),
      email: json['email'] ?? user['email'] ?? '',
      phone: json['phone'] ?? user['phone'],
      salary: double.parse(json['salary'].toString()),
      availableAdvanceLimit: double.parse(
        json['available_advance_limit'].toString(),
      ),
      hireDate: json['hire_date'] != null
          ? DateTime.parse(json['hire_date'])
          : null,
      bankAccount: json['bank_account'],
      bankName: json['bank_name'],
      isActive: json['is_active'] ?? user['is_active'] ?? true,
      documentNumber: json['document_number'] ?? user['document_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'salary': salary,
      'available_advance_limit': availableAdvanceLimit,
      'hire_date': hireDate?.toIso8601String(),
      'bank_account': bankAccount,
      'bank_name': bankName,
      'is_active': isActive,
      'document_number': documentNumber,
    };
  }
}
