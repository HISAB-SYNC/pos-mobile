import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../dashboard/presentation/widgets/app_header.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/category.dart';
import '../../provider/category_provider.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  void _loadCategories() {
    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final shopId = shop.selectedShop?.id ?? 'default-shop';
    final token = auth.token;
    if (token != null && shopId.isNotEmpty) {
      context.read<CategoryProvider>().loadCategories(shopId: shopId, token: token);
    }
  }

  void _showAddEditCategoryDialog({Category? categoryToEdit}) {
    final isEditing = categoryToEdit != null;
    final controller = TextEditingController(text: categoryToEdit?.name ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEditing ? 'Edit Category' : 'New Category',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: AppDecorations.inputDecoration(
            hintText: 'e.g. Beverages, Snacks, Electronics',
            prefixIcon: const Icon(Icons.category_outlined, size: 20, color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMedium)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              HapticFeedback.lightImpact();
              Navigator.pop(dialogCtx);
              final auth = context.read<AuthProvider>();
              final shop = context.read<ShopProvider>();
              final provider = context.read<CategoryProvider>();

              final shopId = shop.selectedShop?.id ?? '';
              final token = auth.token ?? '';

              bool ok;
              if (isEditing) {
                ok = await provider.updateCategory(
                  shopId: shopId,
                  categoryId: categoryToEdit.id,
                  name: name,
                  token: token,
                );
              } else {
                ok = await provider.createCategory(
                  shopId: shopId,
                  name: name,
                  token: token,
                );
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? (isEditing ? 'Category updated successfully' : 'Category created successfully')
                          : (provider.errorMessage ?? 'Action failed'),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.slateDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(isEditing ? 'Save' : 'Create', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorRose, size: 22),
            SizedBox(width: 8),
            Text('Delete Category', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Text('Are you sure you want to delete "${category.name}"? Products under this category will become uncategorized.'),
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
              final provider = context.read<CategoryProvider>();

              final ok = await provider.deleteCategory(
                shopId: shop.selectedShop?.id ?? '',
                categoryId: category.id,
                token: auth.token ?? '',
              );

              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Category deleted'),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final user = auth.currentUser;
    final canManage = user?.isOwner == true || user?.isAdmin == true;
    final categories = categoryProvider.categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Categories'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadCategories(),
          child: Column(
            children: [
              // Header actions
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Categories (${categories.length})',
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (canManage)
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showAddEditCategoryDialog();
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text(
                          'Add Category',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.slateDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),

              // Categories List
              Expanded(
                child: categories.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.category_outlined,
                        title: 'No categories created yet',
                        description: 'Create categories to organize your shop inventory and POS quick filters.',
                        actionLabel: canManage ? '+ Add Category' : null,
                        onAction: canManage ? () => _showAddEditCategoryDialog() : null,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: AppDecorations.cardDecoration,
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.infoBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.category_rounded,
                                    size: 20,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (canManage) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMedium),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      _showAddEditCategoryDialog(categoryToEdit: category);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.errorRose),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      _confirmDeleteCategory(category);
                                    },
                                  ),
                                ],
                              ],
                            ),
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
}
