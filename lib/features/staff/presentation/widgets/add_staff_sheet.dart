import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/staff_model.dart';
import '../../provider/staff_provider.dart';

class AddStaffSheet extends StatefulWidget {
  final StaffMember? staffToEdit;

  const AddStaffSheet({super.key, this.staffToEdit});

  static Future<void> show(BuildContext context, {StaffMember? staffToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddStaffSheet(staffToEdit: staffToEdit),
    );
  }

  @override
  State<AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<AddStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'Shop Sale';

  final List<String> _roles = [
    'Shop Admin',
    'Shop Sale',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.staffToEdit;
    _nameController = TextEditingController(text: s?.name ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');

    final auth = context.read<AuthProvider>();
    final isOwner = auth.currentUser?.isOwner == true;
    if (!isOwner) {
      _selectedRole = 'Shop Sale';
    } else {
      _selectedRole = s != null ? s.role : 'Shop Sale';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final staffProvider = context.read<StaffProvider>();
    final isOwner = auth.currentUser?.isOwner == true;

    final isEditing = widget.staffToEdit != null;
    if (!isEditing) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
    }

    final effectiveRole = (!isOwner) ? 'Shop Sale' : _selectedRole;

    final member = StaffMember(
      id: widget.staffToEdit?.id ?? 'staff-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: effectiveRole,
      joinedDate: widget.staffToEdit?.joinedDate ?? 'Today',
      lastLogin: widget.staffToEdit?.lastLogin ?? 'Never',
      status: widget.staffToEdit?.status ?? 'Active',
    );

    final effectiveShopId = shop.selectedShop?.id ??
        (shop.shops.isNotEmpty ? shop.shops.first.id : (auth.currentUser?.shopId ?? auth.currentUser?.ownedShops?.firstOrNull?.id ?? ''));

    if (effectiveShopId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or create a shop first before registering staff.'),
          backgroundColor: AppColors.errorRose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    bool ok;
    if (isEditing) {
      ok = await staffProvider.updateStaffMember(
        shopId: effectiveShopId,
        token: auth.token,
        member: member,
      );
    } else {
      ok = await staffProvider.createStaffMember(
        shopId: effectiveShopId,
        token: auth.token,
        member: member,
        password: _passwordController.text.trim(),
      );
    }

    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Team member updated' : 'Account created successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final err = staffProvider.errorMessage ?? 'Failed to create team member';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.errorRose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.staffToEdit != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderMedium,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Team Member' : 'Add New Team Member',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderLight),

                // Form fields
                Expanded(
                  child: ListView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      // User Name
                      _buildField(
                        label: 'Full Name',
                        hint: 'Enter name (e.g. Ahmed Hassen)',
                        controller: _nameController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter staff name' : null,
                      ),
                      const SizedBox(height: 14),

                      // Email
                      _buildField(
                        label: 'Email Address',
                        hint: 'Enter email (e.g. ahmed.andalus@gmail.com)',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter email' : null,
                      ),
                      const SizedBox(height: 14),

                      // Role Dropdown
                      Builder(
                        builder: (context) {
                          final auth = context.watch<AuthProvider>();
                          final isOwner = auth.currentUser?.isOwner == true;
                          final availableRoles = isOwner ? _roles : ['Shop Sale'];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Role / Permissions',
                                    style: AppTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  if (!isOwner)
                                    const Text(
                                      'Admin can only add Cashier/Sales',
                                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (!isOwner)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Shop Sale (Cashier)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primaryBlue),
                                    ],
                                  ),
                                )
                              else
                                DropdownButtonFormField<String>(
                                  initialValue: availableRoles.contains(_selectedRole) ? _selectedRole : 'Shop Sale',
                                  decoration: AppDecorations.inputDecoration(hintText: 'Select Role'),
                                  items: availableRoles.map((r) {
                                    return DropdownMenuItem<String>(
                                      value: r,
                                      child: Text(
                                        r == 'Shop Sale' ? 'Shop Sale (Cashier POS)' : 'Shop Admin (Manager)',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedRole = val);
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      if (!isEditing) ...[
                        // Password
                        _buildField(
                          label: 'Password',
                          hint: 'Enter login password (min 6 chars)',
                          controller: _passwordController,
                          obscureText: true,
                          validator: (v) => v == null || v.trim().length < 6 ? 'Password must be at least 6 characters' : null,
                        ),
                        const SizedBox(height: 14),

                        // Confirm Password
                        _buildField(
                          label: 'Confirm Password',
                          hint: 'Re-enter password',
                          controller: _confirmPasswordController,
                          obscureText: true,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Please confirm password' : null,
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Bottom Actions
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.borderLight)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.borderLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Discard',
                            style: TextStyle(
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandLime,
                            foregroundColor: AppColors.brandLimeDarkText,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isEditing ? 'Save Changes' : 'Create Account',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          decoration: AppDecorations.inputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }
}
