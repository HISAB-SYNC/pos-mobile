import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';
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
    final shopId = shop.selectedShop?.id ?? 'default-shop';
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
    final staffProvider = context.watch<StaffProvider>();
    final user = auth.currentUser;
    final isOwner = user?.isOwner == true;
    final canManage = isOwner || user?.isAdmin == true;
    final summary = staffProvider.summary;
    final members = staffProvider.staffMembers;
    final roles = isOwner ? ['All', 'Shop Admin', 'Shop Sale'] : ['All'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Manage Staff'),
      drawer: const AppDrawer(currentRoute: '/staff'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: Column(
            children: [
              // Top KPI Summary Area
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage Teams',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF161B20),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // KPI summary boxes
                    if (isOwner)
                      Row(
                        children: [
                          Expanded(
                            child: _kpiBox(
                              title: 'Total Team Members',
                              value: '${summary.totalMembers}',
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _kpiBox(
                              title: 'Shop Admin',
                              value: '${summary.shopAdmins}',
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _kpiBox(
                              title: 'Shop Sales',
                              value: '${summary.shopSales}',
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _kpiBox(
                              title: 'Total Team Members',
                              value: '${summary.totalMembers}',
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _kpiBox(
                              title: 'Shop Sales',
                              value: '${summary.shopSales}',
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    // Actions row: Search, Download, and "+ Add Team"
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => staffProvider.setSearchQuery(val),
                            decoration: InputDecoration(
                              hintText: 'Search name, email...',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        staffProvider.setSearchQuery('');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Staff list exported successfully')),
                            );
                          },
                          icon: const Icon(Icons.download_outlined, size: 14),
                          label: const Text('Download', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),

                        if (canManage) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => AddStaffSheet.show(context),
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Add Team', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF161B20), // Black button
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Role Filter Bar
              Container(
                height: 44,
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
                      onSelected: (_) => staffProvider.setRoleFilter(role),
                      selectedColor: const Color(0xFF161B20),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF161B20) : const Color(0xFFE2E8F0),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    );
                  },
                ),
              ),
              const Divider(height: 1),

              // Members List
              Expanded(
                child: members.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.manage_accounts_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'No team members found',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, StaffMember member) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Team Member'),
        content: Text('Are you sure you want to remove "${member.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final auth = context.read<AuthProvider>();
              final shop = context.read<ShopProvider>();
              final provider = context.read<StaffProvider>();

              final ok = await provider.deleteStaffMember(
                shopId: shop.selectedShop?.id ?? '',
                token: auth.token,
                staffId: member.id,
              );

              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Team member removed')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name, Email & Role Badge
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isAdmin ? const Color(0xFFEFF6FF) : const Color(0xFFF3E8FF),
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAdmin ? const Color(0xFF2563EB) : const Color(0xFF9333EA),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF161B20),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.email,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAdmin ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  member.role,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isAdmin ? const Color(0xFF2563EB) : const Color(0xFF475569),
                  ),
                ),
              ),
              if (canManage) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                  onPressed: onEdit,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 8),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                  onPressed: onDelete,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 6),
                ),
              ],
            ],
          ),
          const Divider(height: 16),

          // Row 2: Joined Date & Last Login
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Joined: ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  Text(member.joinedDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                ],
              ),
              Row(
                children: [
                  const Text('Last Login: ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  Text(member.lastLogin, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF161B20))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
