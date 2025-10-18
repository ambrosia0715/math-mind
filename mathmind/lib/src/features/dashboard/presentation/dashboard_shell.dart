import 'package:flutter/material.dart';

import '../../home/presentation/home_screen.dart';
import '../../retention/presentation/retention_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../../l10n/app_localizations.dart';

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
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: l10n.navLearn,
          ),
          NavigationDestination(
            icon: Icon(Icons.history_toggle_off_outlined),
            selectedIcon: Icon(Icons.history_toggle_off),
            label: l10n.navRetention,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: l10n.navProfile,
          ),
        ],
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
      ),
    );
  }
}
