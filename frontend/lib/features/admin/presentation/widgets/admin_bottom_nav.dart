import 'package:flutter/material.dart';
import '../pages/admin_main_page.dart';
import '../pages/admin_disbursements_page.dart';
import '../pages/admin_reports_page.dart';
import '../pages/admin_settings_page.dart';

class AdminBottomNav extends StatelessWidget {
  final int currentIndex;

  const AdminBottomNav({
    super.key,
    required this.currentIndex,
  });

  final List<NavItemData> _navItems = const [
    NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Inicio',
      color: Color(0xFF2563EB),
    ),
    NavItemData(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: 'Desembolsos',
      color: Color(0xFF2563EB),
    ),
    NavItemData(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Reportes',
      color: Color(0xFF2563EB),
    ),
    NavItemData(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Config',
      color: Color(0xFF2563EB),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final navHeight = isSmallScreen ? 68.0 : 76.0;
    final iconSize = isSmallScreen ? 22.0 : 24.0;
    final activeIconSize = isSmallScreen ? 24.0 : 26.0;
    final fontSize = isSmallScreen ? 11.0 : 12.0;
    final activeFontSize = isSmallScreen ? 12.0 : 13.0;

    return BottomAppBar(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      height: navHeight,
      color: Colors.white,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_navItems.length, (index) {
          final isSelected = index == currentIndex;
          final item = _navItems[index];

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isSelected) {
                  if (index == 0) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminMainPage()),
                    );
                  } else if (index == 1) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminDisbursementsPage()),
                    );
                  } else if (index == 2) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminReportsPage()),
                    );
                  } else if (index == 3) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminSettingsPage()),
                    );
                  }
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: isSelected ? activeIconSize + 12 : 0,
                        height: isSelected ? activeIconSize + 8 : 0,
                        decoration: BoxDecoration(
                          color: isSelected ? item.color : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: item.color.withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      AnimatedScale(
                        scale: isSelected ? 1.0 : 0.85,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                          size: isSelected ? activeIconSize : iconSize,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isSelected ? item.color : const Color(0xFF94A3B8),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: isSelected ? activeFontSize : fontSize,
                      letterSpacing: isSelected ? 0.2 : 0,
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  const NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}