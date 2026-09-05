import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/shop_provider.dart';
import '../../../auth/provider/auth_provider.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShops();
    });
  }

  Future<void> _loadShops() async {
    final auth = context.read<AuthProvider>();
    final shopProvider = context.read<ShopProvider>();

    final token = auth.token;

    if (token == null) {
      return;
    }

    await shopProvider.loadShops(token);
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = context.watch<ShopProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shops'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: shopProvider.isLoading ? null : _loadShops,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildBody(shopProvider),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: shopProvider.isLoading
            ? null
            : () {
                _showCreateShopDialog();
              },
        icon: const Icon(Icons.add_business),
        label: const Text('Create Shop'),
      ),
    );
  }

  Widget _buildBody(ShopProvider shopProvider) {
    if (shopProvider.isLoading && shopProvider.shops.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (shopProvider.errorMessage != null &&
        shopProvider.shops.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              shopProvider.errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadShops,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (shopProvider.shops.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      itemCount: shopProvider.shops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final shop = shopProvider.shops[index];

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              child: Icon(Icons.store),
            ),
            title: Text(
              shop.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${shop.businessType}\n'
                '${shop.address}\n'
                'Currency: ${shop.currency}',
              ),
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
                  onPressed: () => _confirmDeleteShop(shop),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
              ],
            ),
            onTap: () {
              shopProvider.selectShop(shop);

              Navigator.of(context).pushReplacementNamed('/dashboard');
            },
          ),
        );
      },
    );
  }

  void _confirmDeleteShop(dynamic shop) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text('Delete Shop', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${shop.name}"?\n\nThis will remove all products, categories, sales, and staff linked to this shop.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final auth = context.read<AuthProvider>();
              final shopProvider = context.read<ShopProvider>();
              final token = auth.token;

              if (token != null) {
                final ok = await shopProvider.deleteShop(
                  token: token,
                  shopId: shop.id,
                );

                if (mounted) {
                  if (ok) {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context, rootNavigator: true);
                    await auth.logout();
                    await shopProvider.clear();
                    nav.pushNamedAndRemoveUntil('/login', (route) => false);
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Shop "${shop.name}" deleted successfully.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(shopProvider.errorMessage ?? 'Failed to delete shop'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.store_mall_directory_outlined,
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'No shop yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first shop to get started.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateShopDialog,
            icon: const Icon(Icons.add_business),
            label: const Text('Create Shop'),
          ),
        ],
      ),
    );
  }

  void _showCreateShopDialog() {
    final nameController = TextEditingController();
    final businessTypeController = TextEditingController();
    final addressController = TextEditingController();
    final taxRateController = TextEditingController(text: '0');
    final currencyController = TextEditingController(text: 'ETB');
    final languageController = TextEditingController(text: 'en');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create Shop'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Shop Name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: businessTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Business Type',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: taxRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Tax Rate (%)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: currencyController,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: languageController,
                  decoration: const InputDecoration(
                    labelText: 'Language',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final businessType =
                    businessTypeController.text.trim();
                final address = addressController.text.trim();
                final taxRate =
                    double.tryParse(taxRateController.text.trim()) ?? 0.0;
                final currency =
                    currencyController.text.trim();
                final language =
                    languageController.text.trim();

                if (name.isEmpty ||
                    businessType.isEmpty ||
                    address.isEmpty ||
                    currency.isEmpty ||
                    language.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields.'),
                    ),
                  );
                  return;
                }

                final auth = context.read<AuthProvider>();
                final shopProvider =
                    context.read<ShopProvider>();

                if (auth.token == null) {
                  return;
                }

                final success = await shopProvider.createShop(
                  token: auth.token!,
                  name: name,
                  businessType: businessType,
                  address: address,
                  taxRate: taxRate,
                  currency: currency,
                  language: language,
                );

                if (!dialogContext.mounted) return;

                if (success) {
                  Navigator.of(dialogContext).pop();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shop created successfully.'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        shopProvider.errorMessage ??
                            'Failed to create shop.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}