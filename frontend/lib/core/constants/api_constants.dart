class ApiConstants {
  // URL base del backend Django
  // Para desarrollo local con emulador Android usar 10.0.2.2
  // Para iOS simulator usar localhost
  // Para web usar localhost
  // Para dispositivo físico, usar la IP de la máquina
  
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000', // Web / iOS / Desktop
    // defaultValue: 'http://10.0.2.2:8000', // Android emulator
  );

  // Endpoints API
  static const String apiPrefix = '/api';
  
  // Auth endpoints
  static const String authLogin = '$apiPrefix/auth/login/';
  static const String authRegister = '$apiPrefix/auth/register/';
  static const String authLogout = '$apiPrefix/auth/logout/';
  static const String authProfile = '$apiPrefix/auth/profile/';
  static const String authPasswordChange = '$apiPrefix/auth/password-change/';
  
  // Companies endpoints
  static const String companies = '$apiPrefix/companies/';
  static const String companySettings = '$apiPrefix/companies/settings/';
  
  // Advances endpoints
  static const String advances = '$apiPrefix/advances/';
  static const String advancesPending = '$apiPrefix/advances/pending/';
  static const String advancesApprove = '$apiPrefix/advances/approve/';
  static const String advancesReject = '$apiPrefix/advances/reject/';
  static const String advancesDisburse = '$apiPrefix/advances/disburse/';
  
  // Notifications endpoints
  static const String notifications = '$apiPrefix/notifications/';
  static const String notificationsMarkRead = '$apiPrefix/notifications/mark-read/';
  static const String notificationsUnread = '$apiPrefix/notifications/unread-count/';
  
  // Admin endpoints
  static const String adminUserManagement = '$apiPrefix/admin/user-management/';
  static const String adminVerifyCompany = '$apiPrefix/admin/verify-company';
  static const String adminDashboard = '$apiPrefix/admin/dashboard/';
  
  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Helper para obtener headers con token
  static Map<String, String> getAuthHeaders(String token) => {
    ...headers,
    'Authorization': 'Token $token',
  };
}
