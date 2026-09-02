import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';
import '../../../dashboard/presentation/widgets/app_header.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/settings_model.dart';
import '../../provider/settings_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _stockThresholdController;
  late final TextEditingController _debtDaysController;
  late final TextEditingController _expireDaysController;
  late final TextEditingController _shopAddressController;
  late final TextEditingController _shopTaxRateController;

  bool _lowStockAlert = false;
  bool _debtDueAlert = true;
  bool _productExpireAlert = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    final user = context.read<AuthProvider>().currentUser;
    final shop = context.read<ShopProvider>().selectedShop;

    _usernameController = TextEditingController(text: user?.name.isNotEmpty == true ? user!.name : settings.username);
    _phoneController = TextEditingController(text: settings.phoneNumber);
    _stockThresholdController = TextEditingController(text: settings.stockThreshold.toString());
    _debtDaysController = TextEditingController(text: settings.debtAlertDays.toString());
    _expireDaysController = TextEditingController(text: settings.expireAlertDays.toString());
    _shopAddressController = TextEditingController(text: shop?.address ?? '');
    _shopTaxRateController = TextEditingController(text: shop?.taxRate != null ? shop!.taxRate.toStringAsFixed(1) : '15.0');

    _lowStockAlert = settings.lowStockAlert;
    _debtDueAlert = settings.debtDueAlert;
    _productExpireAlert = settings.productExpireAlert;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _stockThresholdController.dispose();
    _debtDaysController.dispose();
    _expireDaysController.dispose();
    _shopAddressController.dispose();
    _shopTaxRateController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final settingsProvider = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final shopProvider = context.read<ShopProvider>();

    final updated = UserSettings(
      username: _usernameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      lowStockAlert: _lowStockAlert,
      stockThreshold: int.tryParse(_stockThresholdController.text.trim()) ?? 10,
      debtDueAlert: _debtDueAlert,
      debtAlertDays: int.tryParse(_debtDaysController.text.trim()) ?? 3,
      productExpireAlert: _productExpireAlert,
      expireAlertDays: int.tryParse(_expireDaysController.text.trim()) ?? 7,
    );

    settingsProvider.updateSettings(updated);

    // If Owner, update Shop settings via PATCH /shops/:id
    if (auth.currentUser?.isOwner == true && shopProvider.selectedShop != null && auth.token != null) {
      final taxRate = double.tryParse(_shopTaxRateController.text.trim());
      await shopProvider.updateShop(
        token: auth.token!,
        shopId: shopProvider.selectedShop!.id,
        address: _shopAddressController.text.trim(),
        taxRate: taxRate,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!')),
      );
      settingsProvider.setEditing(false);
    }
  }

  void _cancelEdit() {
    final settings = context.read<SettingsProvider>().settings;
    final shop = context.read<ShopProvider>().selectedShop;
    setState(() {
      _usernameController.text = settings.username;
      _phoneController.text = settings.phoneNumber;
      _stockThresholdController.text = settings.stockThreshold.toString();
      _debtDaysController.text = settings.debtAlertDays.toString();
      _expireDaysController.text = settings.expireAlertDays.toString();
      _shopAddressController.text = shop?.address ?? '';
      _shopTaxRateController.text = shop?.taxRate != null ? shop!.taxRate.toStringAsFixed(1) : '15.0';
      _lowStockAlert = settings.lowStockAlert;
      _debtDueAlert = settings.debtDueAlert;
      _productExpireAlert = settings.productExpireAlert;
    });
    context.read<SettingsProvider>().setEditing(false);
  }

  void _confirmDeleteShop(BuildContext context, dynamic shop) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text(
              'Delete Shop',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${shop.name}"?\n\nThis will remove all products, categories, sales, and staff linked to this shop. This action cannot be undone.',
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

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isEditing = settingsProvider.isEditing;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Settings'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Settings Title & Edit Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF161B20),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => settingsProvider.toggleEditing(),
                    icon: Icon(isEditing ? Icons.check : Icons.edit_outlined, size: 14),
                    label: Text(isEditing ? 'Done' : 'Edit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF161B20),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Profile Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Profile',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Please update your profile settings here',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const Divider(height: 24),

                    // Profile Picture
                    Row(
                      children: [
                        const SizedBox(
                          width: 110,
                          child: Text(
                            'Profile Picture',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ),
                        Stack(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              backgroundColor: Color(0xFFEFF6FF),
                              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'),
                            ),
                            if (isEditing)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF161B20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Username
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 110,
                          child: Text(
                            'Username',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _usernameController,
                            enabled: isEditing,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF161B20)),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              hintText: 'Enter username',
                              filled: true,
                              fillColor: isEditing ? Colors.white : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 110,
                          child: Text(
                            'Phone Number',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            enabled: isEditing,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF161B20)),
                            decoration: InputDecoration(
                              prefixIcon: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🇪🇹', style: TextStyle(fontSize: 16)),
                                    SizedBox(width: 4),
                                    Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              filled: true,
                              fillColor: isEditing ? Colors.white : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Store Settings Card (Owner Only)
              Builder(
                builder: (context) {
                  final isOwner = context.watch<AuthProvider>().currentUser?.isOwner == true;
                  final selectedShop = context.watch<ShopProvider>().selectedShop;
                  if (!isOwner || selectedShop == null) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Store Settings (${selectedShop.name})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                selectedShop.currency,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Manage your shop address and default tax rate',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const Divider(height: 24),

                        // Store Address
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 110,
                              child: Text(
                                'Store Address',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _shopAddressController,
                                enabled: isEditing,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF161B20)),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  hintText: 'Enter store address',
                                  filled: true,
                                  fillColor: isEditing ? Colors.white : const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Tax Rate
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 110,
                              child: Text(
                                'Tax Rate (%)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _shopTaxRateController,
                                enabled: isEditing,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF161B20)),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  hintText: 'e.g. 15.0',
                                  filled: true,
                                  fillColor: isEditing ? Colors.white : const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),

                        // Delete Shop Danger Zone
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delete Shop',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Permanently delete this shop and all its data',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => _confirmDeleteShop(context, selectedShop),
                              icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                              label: const Text(
                                'Delete Shop',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFECACA)),
                                backgroundColor: const Color(0xFFFEF2F2),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              // 2. Notifications Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                    ),
                    const Divider(height: 24),

                    // Low Stock Alert
                    _notificationOption(
                      title: 'Low Stock Alert',
                      subtitle: 'Get notified when product stock falls below threshold',
                      value: _lowStockAlert,
                      onChanged: (v) {
                        final newVal = v ?? false;
                        setState(() => _lowStockAlert = newVal);
                        context.read<SettingsProvider>().updateSettings(
                          context.read<SettingsProvider>().settings.copyWith(
                            lowStockAlert: newVal,
                            stockThreshold: int.tryParse(_stockThresholdController.text.trim()) ?? 10,
                          ),
                        );
                      },
                      extraWidget: Row(
                        children: [
                          const SizedBox(width: 32),
                          const Text('Stock threshold', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 54,
                            height: 32,
                            child: TextField(
                              controller: _stockThresholdController,
                              enabled: isEditing,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Units', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    const Divider(height: 24),

                    // Debt Due Alerts
                    _notificationOption(
                      title: 'Debt due Alerts',
                      subtitle: 'Get notified about upcoming debt due dates',
                      value: _debtDueAlert,
                      onChanged: (v) {
                        final newVal = v ?? false;
                        setState(() => _debtDueAlert = newVal);
                        context.read<SettingsProvider>().updateSettings(
                          context.read<SettingsProvider>().settings.copyWith(
                            debtDueAlert: newVal,
                            debtAlertDays: int.tryParse(_debtDaysController.text.trim()) ?? 3,
                          ),
                        );
                      },
                      extraWidget: Row(
                        children: [
                          const SizedBox(width: 32),
                          const Text('Alert Days before due', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 54,
                            height: 32,
                            child: TextField(
                              controller: _debtDaysController,
                              enabled: isEditing,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Days', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    const Divider(height: 24),

                    // Product Expire Alert
                    _notificationOption(
                      title: 'Product expire Alert',
                      subtitle: 'Get notified about products approaching expiration',
                      value: _productExpireAlert,
                      onChanged: (v) {
                        final newVal = v ?? false;
                        setState(() => _productExpireAlert = newVal);
                        context.read<SettingsProvider>().updateSettings(
                          context.read<SettingsProvider>().settings.copyWith(
                            productExpireAlert: newVal,
                            expireAlertDays: int.tryParse(_expireDaysController.text.trim()) ?? 7,
                          ),
                        );
                      },
                      extraWidget: Row(
                        children: [
                          const SizedBox(width: 32),
                          const Text('Alert Days before expiration', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 54,
                            height: 32,
                            child: TextField(
                              controller: _expireDaysController,
                              enabled: isEditing,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Days', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Actions (Cancel X & Save ✓)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _cancelEdit,
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF161B20), // Black button
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?>? onChanged,
    required Widget extraWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              activeColor: const Color(0xFF161B20),
              shape: const CircleBorder(),
              onChanged: onChanged,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        extraWidget,
      ],
    );
  }
}
