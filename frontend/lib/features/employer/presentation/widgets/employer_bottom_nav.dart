import 'package:flutter/material.dart';
import '../pages/employer_main_page.dart';
import '../pages/employer_requests_page.dart';
import '../pages/employer_employees_page.dart';

class EmployerBottomNav extends StatelessWidget {
  final int currentIndex;

  const EmployerBottomNav({
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
      icon: Icons.description_outlined,
      activeIcon: Icons.description,
      label: 'Solicitudes',
      color: Color(0xFF7C3AED),
    ),
    NavItemData(
      icon: Icons.people_outlined,
      activeIcon: Icons.people,
      label: 'Empleados',
      color: Color(0xFF059669),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      height: 105,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_navItems.length, (index) {
          final isSelected = index == currentIndex;
          final item = _navItems[index];

          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                if (index == 0) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const EmployerMainPage()),
                    (route) => false,
                  );
                } else if (index == 1) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const EmployerRequestsPage()),
                    (route) => false,
                  );
                } else if (index == 2) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const EmployerEmployeesPage()),
                    (route) => false,
                  );
                }
              }
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: isSelected ? 48 : 40,
                        height: isSelected ? 48 : 40,
                        decoration: BoxDecoration(
                          color: isSelected ? item.color : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
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
                          size: isSelected ? 24 : 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isSelected ? item.color : const Color(0xFF94A3B8),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: isSelected ? 13 : 12,
                      letterSpacing: isSelected ? 0.3 : 0,
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
