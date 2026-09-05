import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/skeleton_loaders.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../dashboard/presentation/widgets/app_header.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/staff_model.dart';
import '../../provider/staff_provider.dart';
import '../widgets/add_staff_sheet.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  String? _lastShopId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final shopId = shop.selectedShop?.id ??
        (shop.shops.isNotEmpty ? shop.shops.first.id : (auth.currentUser?.shopId ?? auth.currentUser?.ownedShops?.firstOrNull?.id ?? 'default-shop'));
    _lastShopId = shopId;
    final token = auth.token;
    context.read<StaffProvider>().loadStaff(shopId: shopId, token: token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final shop = context.watch<ShopProvider>();
    final staffProvider = context.watch<StaffProvider>();

    final currentShopId = shop.selectedShop?.id ??
        (shop.shops.isNotEmpty ? shop.shops.first.id : (auth.currentUser?.shopId ?? auth.currentUser?.ownedShops?.firstOrNull?.id ?? 'default-shop'));
    if (_lastShopId != null && _lastShopId != currentShopId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    }

    final user = auth.currentUser;
    final isSales = user?.isSales == true;
    final isOwner = user?.isOwner == true;
    final canManage = isOwner || user?.isAdmin == true;

    if (isSales) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppHeader(title: 'Staff & Roles'),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A0F172A),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppColors.warningAmber, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Access Restricted',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Staff and user role permissions are managed by Store Managers and Owners.',
                      style: TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Return to POS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandLime,
                        foregroundColor: AppColors.brandLimeDarkText,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final summary = staffProvider.summary;
    final members = staffProvider.staffMembers;
    final roles = isOwner ? ['All', 'Shop Admin', 'Shop Sale'] : ['All'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Staff & Roles'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: Column(
            children: [
              // Top KPI Summary Area
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Staff Team (${members.length})',
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Staff directory exported to CSV'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.file_download_outlined, size: 20),
                          tooltip: 'Export CSV',
                          color: AppColors.textDark,
                        ),
                        if (canManage) ...[
                          const SizedBox(width: 4),
                          ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              AddStaffSheet.show(context);
                            },
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                            label: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandLime,
                              foregroundColor: AppColors.brandLimeDarkText,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: const Size(0, 34),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Soft-Tinted KPI summary boxes
                    if (isOwner)
                      Row(
                        children: [
                          Expanded(
                            child: _kpiBox(
                              title: 'Total Team',
                              value: '${summary.totalMembers}',
                              accentColor: AppColors.primaryBlue,
                              bgColor: AppColors.infoBg,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _kpiBox(
                              title: 'Shop Admins',
                              value: '${summary.shopAdmins}',
                              accentColor: const Color(0xFF7C3AED),
                              bgColor: const Color(0xFFF5F3FF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _kpiBox(
                              title: 'Cashiers / Sales',
                              value: '${summary.shopSales}',
                              accentColor: AppColors.successEmerald,
                              bgColor: AppColors.successBg,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _kpiBox(
                              title: 'Total Team',
                              value: '${summary.totalMembers}',
                              accentColor: AppColors.primaryBlue,
                              bgColor: AppColors.infoBg,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _kpiBox(
                              title: 'Cashiers / Sales',
                              value: '${summary.shopSales}',
                              accentColor: AppColors.successEmerald,
                              bgColor: AppColors.successBg,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    // Search & Actions
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => staffProvider.setSearchQuery(val),
                      decoration: AppDecorations.inputDecoration(
                        hintText: 'Search staff by name or email...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  staffProvider.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // Role Filter Bar
              if (roles.length > 1) ...[
                Container(
                  height: 48,
                  color: Colors.white,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    scrollDirection: Axis.horizontal,
                    itemCount: roles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final role = roles[index];
                      final isSelected = staffProvider.selectedRoleFilter.toLowerCase() == role.toLowerCase();

                      return ChoiceChip(
                        label: Text(role),
                        selected: isSelected,
                        onSelected: (_) {
                          HapticFeedback.lightImpact();
                          staffProvider.setRoleFilter(role);
                        },
                        selectedColor: AppColors.brandLime,
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? AppColors.brandLimeDarkText : AppColors.textDark,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppColors.brandLimeDark : AppColors.borderLight,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
              ],

              // Members List
              Expanded(
                child: staffProvider.isLoading
                    ? ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: 5,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, __) => const ListRowSkeleton(),
                      )
                    : members.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.groups_outlined,
                            title: staffProvider.searchQuery.isNotEmpty
                                ? 'No team members found'
                                : 'No team members added yet',
                            description: 'Add cashiers and store admins with role-based permissions.',
                            actionLabel: canManage ? '+ Add Staff' : null,
                            onAction: canManage ? () => AddStaffSheet.show(context) : null,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: members.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final member = members[index];
                              return _StaffCard(
                                member: member,
                                canManage: canManage,
                                onEdit: () => AddStaffSheet.show(context, staffToEdit: member),
                                onDelete: () => _confirmDelete(context, member),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiBox({
    required String title,
    required String value,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppDecorations.softCardDecoration(
        backgroundColor: bgColor,
        borderRadius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: accentColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, StaffMember member) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorRose, size: 22),
            SizedBox(width: 8),
            Text('Remove Team Member', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Text('Are you sure you want to remove "${member.name}" from this shop?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMedium)),
          ),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              Navigator.pop(dialogCtx);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final auth = context.read<AuthProvider>();
              final shop = context.read<ShopProvider>();
              final provider = context.read<StaffProvider>();

              final effectiveShopId = shop.selectedShop?.id ??
                  (shop.shops.isNotEmpty ? shop.shops.first.id : (auth.currentUser?.shopId ?? auth.currentUser?.ownedShops?.firstOrNull?.id ?? ''));

              final ok = await provider.deleteStaffMember(
                shopId: effectiveShopId,
                token: auth.token,
                staffId: member.id,
              );

              if (ok) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Team member removed successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffMember member;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffCard({
    required this.member,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = member.isAdmin;

    Color roleBg;
    Color roleColor;

    if (isAdmin) {
      roleBg = AppColors.infoBg;
      roleColor = AppColors.primaryBlue;
    } else {
      roleBg = AppColors.successBg;
      roleColor = AppColors.successEmerald;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: roleBg,
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : 'S',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: roleColor,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.email,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  member.role,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: roleColor,
                  ),
                ),
              ),
              if (canManage) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMedium),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onEdit();
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 8),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.errorRose),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onDelete();
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 6),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 10),

          // Row 2: Joined date & Permissions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Joined ${member.joinedDate}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isAdmin ? 'Full Store Management' : 'Checkout & POS Terminal',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
