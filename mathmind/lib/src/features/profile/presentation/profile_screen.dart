import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/application/auth_provider.dart';
import '../../subscription/application/subscription_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final subscription = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(auth.currentUser?.displayName ?? 'Learner'),
              subtitle: Text(auth.currentUser?.email ?? 'Anonymous account'),
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
                    'Subscription',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current plan: ${subscription.activeTier.name.toUpperCase()}',
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
                              const SnackBar(
                                content: Text(
                                  'Purchases restored (if available).',
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.restore),
                    label: const Text('Restore purchases'),
                  ),
                ],
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
                    'Parent report (Premium)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Premium will unlock a weekly report summarising learning time, strengths,'
                    ' and suggested follow-up activities.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Signed out.')));
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
