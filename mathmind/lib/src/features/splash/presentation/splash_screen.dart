import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/application/auth_provider.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../dashboard/presentation/dashboard_shell.dart';
import '../../../l10n/app_localizations.dart';

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

    try {
      await auth.ensureSignedIn();
      // TODO: Re-enable subscription initialization once RevenueCat integration is ready.
      // await context.read<SubscriptionProvider>().loadOfferings();
    } catch (_) {
      // Continue to dashboard even if network calls fail.
    }

    if (!mounted) return;

    final nextRoute = auth.isSignedIn
        ? DashboardShell.routeName
        : AuthScreen.routeName;

    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.splashLoading,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
