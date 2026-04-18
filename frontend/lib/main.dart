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
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
          fontFamily: GoogleFonts.inter().fontFamily,
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
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();

    if (!mounted) return;

    if (authProvider.isAuthenticated && authProvider.user != null) {
      // Redirigir según rol
      final user = authProvider.user!;
      if (user.isEmployee) {
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
