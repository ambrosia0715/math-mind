import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/application/auth_provider.dart';
import '../../subscription/application/subscription_provider.dart';
import '../../dashboard/presentation/dashboard_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    final subscription = context.read<SubscriptionProvider>();

    try {
      await auth.ensureSignedIn();
      await subscription.loadOfferings();
    } catch (_) {
      // Continue to dashboard even if network calls fail.
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(DashboardShell.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading MathMind',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
