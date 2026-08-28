import '../models/expense_model.dart';

final List<ShopExpense> initialMockExpenses = [
  ShopExpense(
    id: 'exp-001',
    date: 'Jan 18, 2025',
    description: 'Monthly Electricity Bill',
    category: 'Utilities',
    amount: 2450,
    paymentMethod: 'Bank Transfer',
    status: 'Paid',
  ),
  ShopExpense(
    id: 'exp-002',
    date: 'Jan 18, 2025',
    description: 'Staff Overtime Payments',
    category: 'Staff',
    amount: 1390,
    paymentMethod: 'Bank Transfer',
    status: 'Pending',
  ),
  ShopExpense(
    id: 'exp-003',
    date: 'Jan 15, 2025',
    description: 'Cash Register Maintenance',
    category: 'Equipment',
    amount: 1200,
    paymentMethod: 'Credit Card',
    status: 'Overdue',
  ),
  ShopExpense(
    id: 'exp-004',
    date: 'Jan 15, 2025',
    description: 'Weekly newspaper advertisement',
    category: 'Marketing',
    amount: 850,
    paymentMethod: 'Digital Payment',
    status: 'Paid',
  ),
  ShopExpense(
    id: 'exp-005',
    date: 'Jan 10, 2025',
    description: 'Shop Internet Fiber Subscription',
    category: 'Utilities',
    amount: 1150,
    paymentMethod: 'Bank Transfer',
    status: 'Paid',
  ),
];
