class ApiConstants {
  // URL base del backend Django
  // Para desarrollo local con emulador Android usar 10.0.2.2
  // Para iOS simulator usar localhost
  // Para web usar localhost
  // Para dispositivo físico, usar la IP de la máquina

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Local Docker: backend exposed on 8001 by docker-compose.local.yml.
    // Android emulator reaches the host machine through 10.0.2.2.
    // For web/desktop use:
    // --dart-define=API_BASE_URL=http://localhost:8001
    defaultValue: 'http://10.0.2.2:8001',
  );

  // Endpoints API
  static const String apiPrefix = '/api';

  // Auth endpoints
  static const String authLogin = '$apiPrefix/auth/login/';
  static const String authRegister = '$apiPrefix/auth/register/';
  static const String authLogout = '$apiPrefix/auth/logout/';
  static const String authMe = '$apiPrefix/auth/me/';
  static const String authProfile =
      '$apiPrefix/auth/me/'; // Alias para compatibilidad
  static const String authPasswordChange = '$apiPrefix/auth/change-password/';

  // Companies endpoints
  static const String companies = '$apiPrefix/companies/';
  static const String companySettings = '$apiPrefix/companies/settings/';
  static const String myCompany = '$apiPrefix/my-company/';
  static const String employeeProfiles = '$apiPrefix/employee-profiles/';
  static const String employeeContracts = '$apiPrefix/employee-contracts/';

  // Advances endpoints
  static const String advances = '$apiPrefix/advances/';
  static const String advancesCalculate = '$apiPrefix/advances/calculate/';
  static const String advancesPending = '$apiPrefix/advances/pending/';
  // Estos requieren el ID del adelanto: /api/advances/{id}/approve/
  static const String advancesApprove =
      '$apiPrefix/advances'; // + '/{id}/approve/'
  static const String advancesReject =
      '$apiPrefix/advances'; // + '/{id}/reject/'
  static const String advancesDisburse =
      '$apiPrefix/advances'; // + '/{id}/disburse/'

  // Notifications endpoints
  static const String notifications = '$apiPrefix/notifications/';
  static const String notificationsMarkRead =
      '$apiPrefix/notifications/mark-all-read/';
  static const String notificationsUnread =
      '$apiPrefix/notifications/unread-count/';
  static const String notificationsMy =
      '$apiPrefix/notifications/my-notifications/';

  // Admin endpoints
  static const String adminUserManagement = '$apiPrefix/admin/user-management/';
  static const String adminVerifyCompany = '$apiPrefix/admin/verify-company';
  static const String adminDashboard = '$apiPrefix/admin/dashboard/';
  static const String adminReports = '$apiPrefix/admin/reports/';
  static const String adminSettings = '$apiPrefix/admin/settings/';

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
