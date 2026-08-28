class UserSettings {
  final String username;
  final String phoneNumber;
  final String countryCode;
  final bool lowStockAlert;
  final int stockThreshold;
  final bool debtDueAlert;
  final int debtAlertDays;
  final bool productExpireAlert;
  final int expireAlertDays;

  const UserSettings({
    this.username = 'Ahmed Hassen',
    this.phoneNumber = '+251912345678',
    this.countryCode = '+251',
    this.lowStockAlert = false,
    this.stockThreshold = 10,
    this.debtDueAlert = true,
    this.debtAlertDays = 3,
    this.productExpireAlert = false,
    this.expireAlertDays = 7,
  });

  UserSettings copyWith({
    String? username,
    String? phoneNumber,
    String? countryCode,
    bool? lowStockAlert,
    int? stockThreshold,
    bool? debtDueAlert,
    int? debtAlertDays,
    bool? productExpireAlert,
    int? expireAlertDays,
  }) {
    return UserSettings(
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      stockThreshold: stockThreshold ?? this.stockThreshold,
      debtDueAlert: debtDueAlert ?? this.debtDueAlert,
      debtAlertDays: debtAlertDays ?? this.debtAlertDays,
      productExpireAlert: productExpireAlert ?? this.productExpireAlert,
      expireAlertDays: expireAlertDays ?? this.expireAlertDays,
    );
  }
}
