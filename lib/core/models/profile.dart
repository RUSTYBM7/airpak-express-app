enum UserRole { customer, admin, support }

UserRole roleFromString(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'admin':
      return UserRole.admin;
    case 'support':
      return UserRole.support;
    default:
      return UserRole.customer;
  }
}

class AppProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final double walletBalance;
  final int rewardPoints;
  final String companyName;
  final String? defaultAddressId;
  final bool twoFactorEnabled;

  const AppProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.role = UserRole.customer,
    this.walletBalance = 0,
    this.rewardPoints = 0,
    this.companyName = '',
    this.defaultAddressId,
    this.twoFactorEnabled = false,
  });

  factory AppProfile.fromMap(Map<String, dynamic> m) => AppProfile(
        id: m['id']?.toString() ?? '',
        email: m['email']?.toString() ?? '',
        fullName: m['full_name']?.toString(),
        phone: m['phone']?.toString(),
        avatarUrl: m['avatar_url']?.toString(),
        role: roleFromString(m['role']?.toString()),
        walletBalance: (m['wallet_balance'] as num?)?.toDouble() ?? 0,
        rewardPoints: (m['reward_points'] as num?)?.toInt() ?? 0,
        companyName: m['company_name']?.toString() ?? '',
        defaultAddressId: m['default_address_id']?.toString(),
        twoFactorEnabled: m['two_factor_enabled'] as bool? ?? false,
      );

  String get displayName =>
      (fullName != null && fullName!.isNotEmpty) ? fullName! : email.split('@').first;

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'role': role.name,
        'wallet_balance': walletBalance,
        'reward_points': rewardPoints,
        'company_name': companyName,
        'default_address_id': defaultAddressId,
        'two_factor_enabled': twoFactorEnabled,
      };

  AppProfile copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    double? walletBalance,
    int? rewardPoints,
    String? companyName,
    String? defaultAddressId,
    bool? twoFactorEnabled,
  }) =>
      AppProfile(
        id: id,
        email: email,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        role: role,
        walletBalance: walletBalance ?? this.walletBalance,
        rewardPoints: rewardPoints ?? this.rewardPoints,
        companyName: companyName ?? this.companyName,
        defaultAddressId: defaultAddressId ?? this.defaultAddressId,
        twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      );
}
