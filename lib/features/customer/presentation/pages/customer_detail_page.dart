import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/customer_model.dart';
import '../../provider/customer_provider.dart';
import '../widgets/add_customer_sheet.dart';
import '../widgets/add_debt_sheet.dart';
import '../widgets/record_payment_sheet.dart';

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final shop = context.read<ShopProvider>();
      final shopId = shop.selectedShop?.id ?? '';
      final token = auth.token;
      if (shopId.isNotEmpty) {
        context.read<CustomerProvider>().loadCustomerDetail(
              shopId: shopId,
              token: token,
              customerId: widget.customer.id,
            );
        context.read<CustomerProvider>().loadDebts(
              shopId: shopId,
              token: token,
              customerId: widget.customer.id,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final currentCustomer = customerProvider.selectedCustomer?.id == widget.customer.id
        ? customerProvider.selectedCustomer!
        : customerProvider.customers.firstWhere(
            (c) => c.id == widget.customer.id,
            orElse: () => widget.customer,
          );
    final debts = customerProvider.debts
        .where((d) => d.customerId == currentCustomer.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Customer Profile',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              AddCustomerSheet.show(context, customerToEdit: currentCustomer);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Customer Details Card
            _buildCard(
              title: 'Customer Information',
              child: Column(
                children: [
                  _infoRow('Customer Name', currentCustomer.name),
                  _infoRow('Account Code', currentCustomer.customerCode),
                  _infoRow('Phone Number', currentCustomer.phone),
                  if (currentCustomer.email != null && currentCustomer.email!.isNotEmpty)
                    _infoRow('Email Address', currentCustomer.email!),
                  _infoRow('Address / City', currentCustomer.address.isNotEmpty ? currentCustomer.address : 'Addis Ababa'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Debt & Credit Summary Card
            _buildCard(
              title: 'Debt & Credit Balance',
              headerAction: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  AddDebtSheet.show(context, customer: currentCustomer);
                },
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Add Debt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorRose,
                  side: const BorderSide(color: AppColors.borderLight),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              child: Column(
                children: [
                  _infoRow(
                    'Outstanding Debt',
                    '${currentCustomer.totalDebt.toStringAsFixed(0)} ETB',
                    valueColor: currentCustomer.hasDebt ? AppColors.errorRose : AppColors.successEmerald,
                  ),
                  _infoRow('Credit Limit', '${currentCustomer.creditLimit.toStringAsFixed(0)} ETB'),
                  _infoRow(
                    'Available Credit',
                    '${currentCustomer.availableCredit.toStringAsFixed(0)} ETB',
                    valueColor: AppColors.successEmerald,
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: currentCustomer.creditLimit > 0
                          ? (currentCustomer.totalDebt / currentCustomer.creditLimit).clamp(0.0, 1.0)
                          : 0.0,
                      minHeight: 6,
                      backgroundColor: AppColors.inputBackground,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        currentCustomer.creditUsedPercentage > 80
                            ? AppColors.errorRose
                            : currentCustomer.creditUsedPercentage > 50
                                ? AppColors.warningAmber
                                : AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Open Debts & Payment Records Card
            if (debts.isNotEmpty) ...[
              _buildCard(
                title: 'Open Debt Records',
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: debts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final debt = debts[index];
                    final isPaid = debt.isPaid;
                    final isPartial = debt.isPartial;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppDecorations.softCardDecoration(
                        backgroundColor: AppColors.inputBackground,
                        borderRadius: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${debt.amount.toStringAsFixed(0)} ETB',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isPaid
                                            ? AppColors.successBg
                                            : isPartial
                                                ? AppColors.warningBg
                                                : AppColors.errorBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        debt.status,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: isPaid
                                              ? AppColors.successEmerald
                                              : isPartial
                                                  ? AppColors.warningAmber
                                                  : AppColors.errorRose,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (debt.notes != null && debt.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    debt.notes!,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                                if (debt.dueDate != null && debt.dueDate!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Due: ${debt.dueDate!.length > 10 ? debt.dueDate!.substring(0, 10) : debt.dueDate}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!isPaid)
                            ElevatedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                RecordPaymentSheet.show(
                                  context,
                                  customer: currentCustomer,
                                  specificDebt: debt,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandLime,
                                foregroundColor: AppColors.brandLimeDarkText,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text('Pay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 4. Recent Transactions Card
            _buildCard(
              title: 'Transactions History',
              child: currentCustomer.transactions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: Text('No transaction history recorded', style: TextStyle(color: AppColors.textMuted)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentCustomer.transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final tx = currentCustomer.transactions[index];
                        final isUnpaid = tx.status.toUpperCase() == 'PENDING' || tx.status.toLowerCase() == 'unpaid';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: AppDecorations.softCardDecoration(
                            backgroundColor: AppColors.inputBackground,
                            borderRadius: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.title,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tx.date.isNotEmpty ? (tx.date.length > 10 ? tx.date.substring(0, 10) : tx.date) : '',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${tx.amount.toStringAsFixed(0)} ETB',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isUnpaid ? AppColors.errorBg : AppColors.successBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tx.status,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: isUnpaid ? AppColors.errorRose : AppColors.successEmerald,
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
            ),
            const SizedBox(height: 20),

            // Bottom Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      RecordPaymentSheet.show(context, customer: currentCustomer);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandLime,
                      foregroundColor: AppColors.brandLimeDarkText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment reminder SMS sent to ${currentCustomer.phone}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Send Reminder', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    Widget? headerAction,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
              ),
              if (headerAction != null) headerAction,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
