import 'package:flutter/material.dart';

import '../services/api_service.dart';

enum AppPopupType { success, error, warning, info, recovered, undo }

class AppPopup {
  static void _safePop<T extends Object?>(BuildContext context, [T? result]) {
    try {
      Navigator.maybePop<T>(context, result).catchError((_) => false);
    } catch (_) {
      // The route may already be gone if the caller navigated immediately.
    }
  }

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    AppPopupType type = AppPopupType.info,
    String primaryLabel = 'Aceptar',
  }) {
    final displayMessage = type == AppPopupType.error
        ? ApiException.cleanErrorMessage(message)
        : message;
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: primaryLabel,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _AppPopupCard(
          title: title,
          message: displayMessage,
          type: type,
          primaryLabel: primaryLabel,
          onPrimary: () => _safePop(context),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    AppPopupType type = AppPopupType.warning,
    String primaryLabel = 'Confirmar',
    String secondaryLabel = 'Cancelar',
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: secondaryLabel,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _AppPopupCard(
          title: title,
          message: message,
          type: type,
          primaryLabel: primaryLabel,
          secondaryLabel: secondaryLabel,
          onPrimary: () => _safePop(context, true),
          onSecondary: () => _safePop(context, false),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    return result ?? false;
  }
}

class _AppPopupCard extends StatelessWidget {
  final String title;
  final String message;
  final AppPopupType type;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;

  const _AppPopupCard({
    required this.title,
    required this.message,
    required this.type,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _themeFor(type);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.86,
          constraints: const BoxConstraints(maxWidth: 390),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.color.withValues(alpha: 0.24),
                blurRadius: 34,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.color.withValues(alpha: 0.16),
                        theme.softColor,
                        Colors.white,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.color, theme.darkColor],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: theme.color.withValues(alpha: 0.28),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Icon(
                            theme.icon,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.42,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                  child: Row(
                    children: [
                      if (secondaryLabel != null) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onSecondary,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            child: Text(secondaryLabel!),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: FilledButton(
                          onPressed: onPrimary,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          child: Text(primaryLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _PopupTheme _themeFor(AppPopupType type) {
    return switch (type) {
      AppPopupType.success => const _PopupTheme(
        color: Color(0xFF16A34A),
        darkColor: Color(0xFF15803D),
        softColor: Color(0xFFF0FDF4),
        icon: Icons.check_circle_outline,
      ),
      AppPopupType.error => const _PopupTheme(
        color: Color(0xFFDC2626),
        darkColor: Color(0xFFB91C1C),
        softColor: Color(0xFFFEF2F2),
        icon: Icons.error_outline,
      ),
      AppPopupType.warning => const _PopupTheme(
        color: Color(0xFFF97316),
        darkColor: Color(0xFFC2410C),
        softColor: Color(0xFFFFF7ED),
        icon: Icons.warning_amber_rounded,
      ),
      AppPopupType.info => const _PopupTheme(
        color: Color(0xFF7C3AED),
        darkColor: Color(0xFF5B21B6),
        softColor: Color(0xFFF5F3FF),
        icon: Icons.info_outline,
      ),
      AppPopupType.recovered => const _PopupTheme(
        color: Color(0xFF0EA5E9),
        darkColor: Color(0xFF0284C7),
        softColor: Color(0xFFF0F9FF),
        icon: Icons.payments_outlined,
      ),
      AppPopupType.undo => const _PopupTheme(
        color: Color(0xFFF59E0B),
        darkColor: Color(0xFFD97706),
        softColor: Color(0xFFFFFBEB),
        icon: Icons.arrow_back_rounded,
      ),
    };
  }
}

class _PopupTheme {
  final Color color;
  final Color darkColor;
  final Color softColor;
  final IconData icon;

  const _PopupTheme({
    required this.color,
    required this.darkColor,
    required this.softColor,
    required this.icon,
  });
}
