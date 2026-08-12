import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/provider/auth_provider.dart';

/// Temporary placeholder so login has somewhere to navigate to.
/// Replace with the real catalog screen on Day 4-5.
class CatalogPlaceholderPage extends StatelessWidget {
  const CatalogPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog (placeholder)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          user == null
              ? 'No user'
              : 'Logged in as ${user.name} (${user.role})\nShop ID: ${user.shopId ?? "none (Owner)"}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}