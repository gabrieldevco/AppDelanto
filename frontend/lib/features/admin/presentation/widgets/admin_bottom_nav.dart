import 'package:flutter/material.dart';
import '../pages/admin_main_page.dart';

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
    return BottomAppBar(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      height: 80,
      color: Colors.white,
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
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminMainPage()),
                      (route) => false,
                    );
                  }
                  // TODO: Navigate to other pages
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: double.infinity,
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
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
                            width: isSelected ? 32 : 28,
                            height: isSelected ? 32 : 28,
                            decoration: BoxDecoration(
                              color: isSelected ? item.color : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: item.color.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
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
                              size: isSelected ? 22 : 20,
                            ),
                          ),
                        ],
                      ),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isSelected ? item.color : const Color(0xFF94A3B8),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: isSelected ? 15 : 14,
                          letterSpacing: isSelected ? 0.3 : 0,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
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
