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
import '../../models/expense_model.dart';
import '../../provider/expenses_provider.dart';
import '../widgets/add_expense_sheet.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Utilities',
    'Staff',
    'Equipment',
    'Marketing',
    'Rent',
  ];

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
    context.read<ExpensesProvider>().loadExpenses(shopId: shopId, token: token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final expensesProvider = context.watch<ExpensesProvider>();
    final user = auth.currentUser;
    final canManage = user?.isOwner == true || user?.isAdmin == true;
    final summary = expensesProvider.summary;
    final expenses = expensesProvider.expenses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Expenses & Overhead'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: Column(
            children: [
              // Top KPI Summary Container
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
                            'Expenses Summary',
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
                                content: Text('Expenses report exported to PDF'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.file_download_outlined, size: 20),
                          tooltip: 'Export PDF',
                          color: AppColors.textDark,
                        ),
                        if (canManage) ...[
                          const SizedBox(width: 4),
                          ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              AddExpenseSheet.show(context);
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.slateDark,
                              foregroundColor: Colors.white,
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

                    // 3 Soft-Tinted KPI summary boxes
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: _kpiBox(
                            title: 'Total Expenses',
                            value: '${summary.totalExpenses.toStringAsFixed(0)} ETB',
                            badgeText: '+${summary.growthPercent}% last mo.',
                            accentColor: AppColors.errorRose,
                            bgColor: AppColors.errorBg,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: _kpiBox(
                            title: 'This Week',
                            value: '${summary.thisWeek.toStringAsFixed(0)} ETB',
                            badgeText: 'Current cycle',
                            accentColor: AppColors.textMedium,
                            bgColor: AppColors.inputBackground,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: _kpiBox(
                            title: 'Pending',
                            value: '${summary.pendingPayment.toStringAsFixed(0)} ETB',
                            badgeText: 'Due soon',
                            accentColor: AppColors.warningAmber,
                            bgColor: AppColors.warningBg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search field
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => expensesProvider.setSearchQuery(val),
                      decoration: AppDecorations.inputDecoration(
                        hintText: 'Search expense, description...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  expensesProvider.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // Category Filter Bar
              Container(
                height: 48,
                color: Colors.white,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = expensesProvider.selectedCategoryFilter.toLowerCase() == cat.toLowerCase();

                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) {
                        HapticFeedback.lightImpact();
                        expensesProvider.setCategoryFilter(cat);
                      },
                      selectedColor: AppColors.slateDark,
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                      backgroundColor: AppColors.inputBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.slateDark : AppColors.borderLight,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),

              // Expenses List
              Expanded(
                child: expensesProvider.isLoading
                    ? ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: 6,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, __) => const ListRowSkeleton(),
                      )
                    : expenses.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.receipt_long_outlined,
                            title: expensesProvider.searchQuery.isNotEmpty
                                ? 'No expense found'
                                : 'No expenses recorded',
                            description: expensesProvider.searchQuery.isNotEmpty
                                ? 'No expense matches "${expensesProvider.searchQuery}"'
                                : 'Record operational costs, utility bills, rent, and staff wages.',
                            actionLabel: canManage ? '+ Add Expense' : null,
                            onAction: canManage ? () => AddExpenseSheet.show(context) : null,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: expenses.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final expense = expenses[index];
                              return _ExpenseCard(
                                expense: expense,
                                canManage: canManage,
                                onEdit: () => AddExpenseSheet.show(context, expenseToEdit: expense),
                                onDelete: () => _confirmDelete(context, expense),
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
    required String badgeText,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AppDecorations.softCardDecoration(
        backgroundColor: bgColor,
        borderRadius: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: accentColor)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            badgeText,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: accentColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ShopExpense expense) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorRose, size: 22),
            SizedBox(width: 8),
            Text('Delete Expense', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Text('Are you sure you want to delete "${expense.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMedium)),
          ),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              Navigator.pop(dialogCtx);
              final auth = context.read<AuthProvider>();
              final shop = context.read<ShopProvider>();
              final provider = context.read<ExpensesProvider>();

              final ok = await provider.deleteExpense(
                shopId: shop.selectedShop?.id ?? '',
                token: auth.token,
                expenseId: expense.id,
              );

              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expense deleted successfully'),
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

class _ExpenseCard extends StatelessWidget {
  final ShopExpense expense;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeBg;
    Color badgeTextColor;

    if (expense.isPaid) {
      badgeBg = AppColors.successBg;
      badgeTextColor = AppColors.successEmerald;
    } else if (expense.isPending) {
      badgeBg = AppColors.warningBg;
      badgeTextColor = AppColors.warningAmber;
    } else {
      badgeBg = AppColors.errorBg;
      badgeTextColor = AppColors.errorRose;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Description, Category & Status Badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            expense.category,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textMedium),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('• ${expense.paymentMethod}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  expense.status,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: badgeTextColor,
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

          // Row 2: Date & Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    expense.date,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              Text(
                '${expense.amount.toStringAsFixed(0)} ETB',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.slateDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
