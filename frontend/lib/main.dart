import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/advances/presentation/providers/advance_provider.dart';
import 'features/companies/presentation/providers/company_provider.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';
import 'features/admin/presentation/providers/admin_provider.dart';
import 'features/employee/presentation/pages/employee_main_page.dart';
import 'features/employer/presentation/pages/employer_main_page.dart';
import 'features/admin/presentation/pages/admin_main_page.dart';
import 'core/services/api_service.dart';
import 'core/widgets/app_popup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicio de API
  await apiService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdvanceProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'AppDelanta',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(
                seedColor: const Color(0xFF2563EB),
                brightness: Brightness.light,
              ).copyWith(
                primary: const Color(0xFF2563EB),
                secondary: const Color(0xFF0F766E),
                tertiary: const Color(0xFF7C3AED),
                surface: Colors.white,
                surfaceContainerHighest: const Color(0xFFF1F5F9),
                error: const Color(0xFFDC2626),
              ),
          scaffoldBackgroundColor: const Color(0xFFF6F8FB),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme().apply(
            bodyColor: const Color(0xFF111827),
            displayColor: const Color(0xFF111827),
          ),
          fontFamily: GoogleFonts.inter().fontFamily,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF111827),
            elevation: 0,
            centerTitle: false,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD8DEE9)),
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD8DEE9)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD8DEE9)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 1.4,
              ),
            ),
          ),
        ),
        home: const AppInitializer(),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Guardar referencias antes de los awaits
    final authProvider = context.read<AuthProvider>();

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!hasSeenOnboarding) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingPage()),
        );
      }
      return;
    }

    // Verificar sesión
    await authProvider.initialize();

    if (!mounted) return;

    if (authProvider.isAuthenticated && authProvider.user != null) {
      // Redirigir según rol
      final user = authProvider.user!;
      if (user.isEmployee) {
        if (user.employeeProfile?.isPendingApproval ?? false) {
          await authProvider.logout();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
          await AppPopup.show(
            context,
            title: 'Verificacion pendiente',
            message:
                'Debes esperar a que tu empleador verifique tu informacion para poder ingresar.',
            type: AppPopupType.warning,
          );
          return;
        }
        if (user.employeeProfile?.isRejected ?? false) {
          await authProvider.logout();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
          await AppPopup.show(
            context,
            title: 'Vinculacion no aprobada',
            message:
                'Tu empleador no aprobo la vinculacion. Contacta a tu empleador para revisar tu informacion.',
            type: AppPopupType.error,
          );
          return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeMainPage()),
        );
      } else if (user.isEmployer) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployerMainPage()),
        );
      } else if (user.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminMainPage()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando...'),
          ],
        ),
      ),
    );
  }
}
