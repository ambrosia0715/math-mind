import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/application/auth_provider.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../subscription/application/subscription_provider.dart';
import '../../../l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final subscription = context.watch<SubscriptionProvider>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileAppBarTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(
                auth.currentUser?.displayName ?? l10n.generalLearnerFallback,
              ),
              subtitle: Text(
                auth.currentUser?.email ?? l10n.profileAnonymousAccount,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileSubscriptionSection,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.profileCurrentPlan(
                      subscription.activeTier.name.toUpperCase(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: subscription.offerings == null
                        ? null
                        : () async {
                            await subscription.restore();
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.profileRestoreResult),
                              ),
                            );
                          },
                    icon: const Icon(Icons.restore),
                    label: Text(l10n.profileRestorePurchases),
                  ),
                ],
              ),
            ),
          ),
          // Parent report section removed
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await auth.signOut();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(l10n.profileSignedOut)));
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AuthScreen.routeName, (route) => false);
            },
            icon: const Icon(Icons.logout),
            label: Text(l10n.profileSignOut),
          ),
        ],
      ),
    );
  }
}
