import 'package:flutter/material.dart';
import 'package:frontend/core/utils/responsive_utils.dart';
import 'package:frontend/core/widgets/app_popup.dart';
import 'package:provider/provider.dart';
import '../../../admin/presentation/pages/admin_main_page.dart';
import '../../../employee/presentation/pages/employee_main_page.dart';
import '../../../employer/presentation/pages/employer_main_page.dart';
import '../providers/auth_provider.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Ingresa tu correo y contraseña', const Color(0xFFEA580C));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(email: email, password: password);

    if (success && mounted) {
      final user = authProvider.user;
      if (user == null) return;

      if (user.isEmployee) {
        if (user.employeeProfile?.isPendingApproval ?? false) {
          await authProvider.logout();
          if (!mounted) return;
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
        if (!(user.company?.isVerified ?? false) &&
            !(user.company?.isPreapproved ?? false)) {
          await authProvider.logout();
          if (!mounted) return;
          await AppPopup.show(
            context,
            title: 'Verificacion pendiente',
            message:
                'Tu empresa aun no ha sido preaprobada por el administrador. Podras ingresar cuando la documentacion sea revisada.',
            type: AppPopupType.warning,
          );
          return;
        }
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
    } else if (mounted) {
      _showMessage(
        authProvider.errorMessage ?? 'Credenciales incorrectas',
        const Color(0xFFDC2626),
      );
    }
  }

  void _showMessage(String message, Color color) {
    AppPopup.show(
      context,
      title: color == const Color(0xFFDC2626)
          ? 'No se pudo ingresar'
          : 'Campos pendientes',
      message: message,
      type: color == const Color(0xFFDC2626)
          ? AppPopupType.error
          : AppPopupType.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFBF6),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF1E6),
                    Color(0xFFFFFAF5),
                    Color(0xFFFFFBF7),
                    Color(0xFFFFFFFF),
                  ],
                  stops: [0, 0.34, 0.68, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _LoginPatternPainter()),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -74,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF14B8A6).withValues(alpha: 0.12),
                    const Color(0xFF14B8A6).withValues(alpha: 0.00),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 72,
            right: -92,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                width: 210,
                height: 82,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.56),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 124,
            left: -86,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                width: 178,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5).withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -42,
            left: -56,
            right: -56,
            child: Transform.rotate(
              angle: -0.10,
              child: Container(
                height: 245,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF7A1A).withValues(alpha: 0.26),
                      const Color(0xFFF97316).withValues(alpha: 0.18),
                      const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(36),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLandscapePhone = ResponsiveUtils.isLandscapePhone(
                  context,
                );
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isLandscapePhone ? 18 : 22,
                    isLandscapePhone ? 10 : 18,
                    isLandscapePhone ? 18 : 22,
                    isLandscapePhone ? 18 : 28,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxWidth: isLandscapePhone ? 820 : double.infinity,
                    ),
                    child: Center(
                      child: isLandscapePhone
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: _buildBrand(compact: true)),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildLoginCard(isLoading, compact: true),
                                      const SizedBox(height: 10),
                                      _buildFooter(),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                const SizedBox(height: 14),
                                _buildBrand(),
                                const SizedBox(height: 24),
                                _buildLoginCard(isLoading),
                                const SizedBox(height: 16),
                                _buildFooter(),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand({bool compact = false}) {
    return Column(
      children: [
        _buildBrandMark(compact: compact),
        SizedBox(height: compact ? 10 : 18),
        Text(
          'AppDelanta',
          style: TextStyle(
            fontSize: compact ? 28 : 35,
            fontWeight: FontWeight.w900,
            color: Color(0xFF101828),
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: compact ? 5 : 8),
        const Text(
          'Tu dinero disponible, claro y seguro.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.25,
            fontWeight: FontWeight.w600,
            color: Color(0xFF667085),
          ),
        ),
        /* SizedBox(height: compact ? 10 : 16),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _TrustPill(icon: Icons.bolt_rounded, label: 'Rápido'),
            _TrustPill(icon: Icons.lock_rounded, label: 'Protegido'),
            _TrustPill(icon: Icons.phone_iphone_rounded, label: 'Móvil'),
          ],
        ),
        if (!compact) ...[const SizedBox(height: 14), const _BrandBadge()], */
      ],
    );
  }

  Widget _buildBrandMark({bool compact = false}) {
    return Container(
      width: compact ? 70 : 92,
      height: compact ? 70 : 92,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8A3D), Color(0xFFF97316), Color(0xFFB45309)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFFB45309).withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 58,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9A3412).withValues(alpha: 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 21,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDD5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 21,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDD5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFF97316),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.attach_money_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(bool isLoading, {bool compact = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9A3412).withValues(alpha: 0.08),
            blurRadius: 38,
            offset: const Offset(0, 22),
          ),
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 78,
            height: 5,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFB86B),
                  Color(0xFFFF6B1A),
                  Color(0xFFD97706),
                ],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: compact ? 14 : 18),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF8A3D), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF97316).withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido de nuevo',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Accede a tu panel en segundos',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF667085),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 18),
          _buildLoginInsightStrip(compact: compact),
          SizedBox(height: compact ? 14 : 20),
          _buildLabel('Correo electronico'),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: _inputDecoration(
              hintText: 'correo@empresa.com',
              icon: Icons.mail_outline_rounded,
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          Row(
            children: [
              _buildLabel('Contraseña'),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.help_outline_rounded, size: 14),
                label: const Text('Olvidé mi contraseña'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFF97316),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => isLoading ? null : _login(),
            decoration: _inputDecoration(
              hintText: 'Tu contraseña',
              icon: Icons.key_rounded,
              suffix: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF667085),
                  size: 20,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 16 : 24),
          _buildPrimaryButton(isLoading, compact: compact),
          SizedBox(height: compact ? 10 : 12),
          SizedBox(
            width: double.infinity,
            height: compact ? 46 : 52,
            child: OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
              label: const Text('Crear cuenta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF9A3412),
                side: const BorderSide(color: Color(0xFFFED7AA)),
                backgroundColor: const Color(0xFFFFF7ED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginInsightStrip({required bool compact}) {
    final items = [
      (
        icon: Icons.verified_user_rounded,
        label: 'Acceso seguro',
        color: const Color(0xFF0D9488),
      ),
      (
        icon: Icons.speed_rounded,
        label: 'Panel rapido',
        color: const Color(0xFFF97316),
      ),
    ];

    return Container(
      padding: EdgeInsets.all(compact ? 9 : 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFFFF7ED),
            Colors.white,
            const Color(0xFFF0FDFA).withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF8E4D3)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: items[index].color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      items[index].icon,
                      size: 15,
                      color: items[index].color,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      items[index].label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF475467),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (index == 0)
              Container(width: 1, height: 24, color: const Color(0xFFF1E4D6)),
          ],
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(bool isLoading, {required bool compact}) {
    return Container(
      width: double.infinity,
      height: compact ? 48 : 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFF8A1D), Color(0xFFF97316), Color(0xFFEA580C)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.26),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _login,
        icon: isLoading
            ? const SizedBox.shrink()
            : const Icon(Icons.arrow_forward_rounded, size: 20),
        label: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : const Text('Ingresar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: const Color(0xFFFDBA74),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.90)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9A3412).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: Color(0xFFB45309), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tus datos se protegen con autenticacion segura.',
              style: TextStyle(
                color: Color(0xFF667085),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF334155),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: const Color(0xFF9A3412), size: 20),
      suffixIcon: suffix,
      hintStyle: const TextStyle(
        color: Color(0xFFA8B3C2),
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: const Color(0xFFFFFCF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF1E4D6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF1E4D6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.6),
      ),
    );
  }
}

class _LoginPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFF97316).withValues(alpha: 0.045)
      ..strokeWidth = 1;
    final dotPaint = Paint()
      ..color = const Color(0xFF0D9488).withValues(alpha: 0.055);

    for (var i = 0; i < 6; i++) {
      final y = 92.0 + (i * 38);
      canvas.drawLine(
        Offset(size.width * 0.58, y),
        Offset(size.width + 18, y - 22),
        linePaint,
      );
    }

    for (var i = 0; i < 9; i++) {
      final x = 26.0 + (i * 38);
      final y = size.height - 180 + ((i % 3) * 28);
      canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
    }

    final arcPaint = Paint()
      ..color = const Color(0xFFEA580C).withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(
      Offset(size.width + 32, size.height * 0.48),
      96,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
