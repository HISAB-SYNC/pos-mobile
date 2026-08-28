import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
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

    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final staffProvider = context.read<StaffProvider>();
    final isOwner = auth.currentUser?.isOwner == true;

    final isEditing = widget.staffToEdit != null;
    if (!isEditing) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }
    }

    // Admin can ONLY add SALES staff
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

    bool ok;
    if (isEditing) {
      ok = await staffProvider.updateStaffMember(
        shopId: shop.selectedShop?.id ?? 'default-shop',
        token: auth.token,
        member: member,
      );
    } else {
      ok = await staffProvider.createStaffMember(
        shopId: shop.selectedShop?.id ?? 'default-shop',
        token: auth.token,
        member: member,
        password: _passwordController.text.trim(),
      );
    }

    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Team member updated' : 'Account created successfully')),
        );
      } else {
        final err = staffProvider.errorMessage ?? 'Failed to create team member';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Team Member' : 'Add New Team Member',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF161B20),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Form fields
                Expanded(
                  child: ListView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      // User Name
                      _buildField(
                        label: 'User Name',
                        hint: 'Enter name (e.g. Ahmed Hassen)',
                        controller: _nameController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter user name' : null,
                    ),
                    const SizedBox(height: 12),

                    // Email
                    _buildField(
                      label: 'Email',
                      hint: 'Enter email (e.g. ahmed.andalus@gmail.com)',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter email' : null,
                    ),
                    const SizedBox(height: 12),

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
                                const Text(
                                  'Role',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                if (!isOwner)
                                  const Text(
                                    'Admin can only add Sales',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (!isOwner)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Shop Sale',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF161B20),
                                      ),
                                    ),
                                    Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF2563EB)),
                                  ],
                                ),
                              )
                            else
                              DropdownButtonFormField<String>(
                                value: availableRoles.contains(_selectedRole) ? _selectedRole : 'Shop Sale',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF161B20),
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                ),
                                items: availableRoles.map((r) {
                                  return DropdownMenuItem<String>(
                                    value: r,
                                    child: Text(
                                      r,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: r == 'Shop Sale' ? FontWeight.w800 : FontWeight.w600,
                                        color: const Color(0xFF161B20),
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
                    const SizedBox(height: 12),

                    if (!isEditing) ...[
                      // Password
                      _buildField(
                        label: 'Password',
                        hint: 'Enter Password',
                        controller: _passwordController,
                        obscureText: true,
                        validator: (v) => v == null || v.trim().length < 6 ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: 12),

                      // Confirm Password
                      _buildField(
                        label: 'Confirm Password',
                        hint: 'Confirm Password',
                        controller: _confirmPasswordController,
                        obscureText: true,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please confirm password' : null,
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Discard',
                          style: TextStyle(
                            color: Color(0xFF475569),
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
                          backgroundColor: const Color(0xFF161B20), // Black button
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isEditing ? 'Save Changes' : 'Create Account',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Color(0xFF161B20)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }
}
