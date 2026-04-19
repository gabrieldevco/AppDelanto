class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phone;
  final String? documentNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Perfiles específicos por rol
  final EmployeeProfile? employeeProfile;
  final AdminProfile? adminProfile;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phone,
    this.documentNumber,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.employeeProfile,
    this.adminProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? 'employee',
      phone: json['phone'],
      documentNumber: json['document_number'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : DateTime.now(),
      employeeProfile: json['employee_profile'] != null
          ? EmployeeProfile.fromJson(json['employee_profile'])
          : json['profile'] != null  // Backend devuelve 'profile' en algunos endpoints
              ? EmployeeProfile.fromJson(json['profile'])
              : null,
      adminProfile: json['admin_profile'] != null
          ? AdminProfile.fromJson(json['admin_profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'phone': phone,
      'document_number': documentNumber,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'employee_profile': employeeProfile?.toJson(),
      'admin_profile': adminProfile?.toJson(),
    };
  }

  String get fullName => '$firstName $lastName'.trim();
  
  bool get isEmployee => role == 'employee';
  bool get isEmployer => role == 'employer';
  bool get isAdmin => role == 'admin';

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? phone,
    String? documentNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    EmployeeProfile? employeeProfile,
    AdminProfile? adminProfile,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      documentNumber: documentNumber ?? this.documentNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      employeeProfile: employeeProfile ?? this.employeeProfile,
      adminProfile: adminProfile ?? this.adminProfile,
    );
  }
}

class EmployeeProfile {
  final int id;
  final int? companyId;
  final String? companyName;
  final double salary;
  final double availableAdvanceLimit;
  final DateTime? hireDate;
  final String? bankAccount;
  final String? bankName;

  EmployeeProfile({
    required this.id,
    this.companyId,
    this.companyName,
    required this.salary,
    required this.availableAdvanceLimit,
    this.hireDate,
    this.bankAccount,
    this.bankName,
  });

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      id: json['id'] ?? 0,
      companyId: json['company'],
      companyName: json['company_name'],
      salary: json['salary'] != null ? double.parse(json['salary'].toString()) : 0.0,
      availableAdvanceLimit: json['available_advance_limit'] != null 
          ? double.parse(json['available_advance_limit'].toString()) 
          : 0.0,
      hireDate: json['hire_date'] != null ? DateTime.tryParse(json['hire_date']) : null,
      bankAccount: json['bank_account'],
      bankName: json['bank_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company': companyId,
      'company_name': companyName,
      'salary': salary,
      'available_advance_limit': availableAdvanceLimit,
      'hire_date': hireDate?.toIso8601String(),
      'bank_account': bankAccount,
      'bank_name': bankName,
    };
  }
}

class AdminProfile {
  final int id;
  final bool isSuperAdmin;
  final Map<String, dynamic>? permissions;

  AdminProfile({
    required this.id,
    required this.isSuperAdmin,
    this.permissions,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      id: json['id'],
      isSuperAdmin: json['is_super_admin'] ?? false,
      permissions: json['permissions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_super_admin': isSuperAdmin,
      'permissions': permissions,
    };
  }
}
