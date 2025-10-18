import 'package:flutter/material.dart';

import '../../home/presentation/home_screen.dart';
import '../../retention/presentation/retention_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  static const routeName = '/dashboard';

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _index = 0;

  final _pages = const [HomeScreen(), RetentionScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_toggle_off_outlined),
            selectedIcon: Icon(Icons.history_toggle_off),
            label: 'Retention',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
      ),
    );
  }
}
