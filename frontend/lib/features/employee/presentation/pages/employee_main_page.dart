import 'package:flutter/material.dart';
import 'employee_home_page.dart';
import 'employee_request_page.dart';
import 'employee_history_page.dart';

class EmployeeMainPage extends StatefulWidget {
  const EmployeeMainPage({super.key});

  @override
  State<EmployeeMainPage> createState() => _EmployeeMainPageState();
}

class _EmployeeMainPageState extends State<EmployeeMainPage>
    with SingleTickerProviderStateMixin {
  final int _currentIndex = 0;

  final List<Widget> _pages = [
    const EmployeeHomePage(),
    const EmployeeRequestPage(),
    const EmployeeHistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
