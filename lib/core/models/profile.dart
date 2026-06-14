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

/// Account status — controlled by admin.
/// Defaults to [active] for new accounts.
enum AccountStatus { active, verified, pending, blocked, suspended }

AccountStatus accountStatusFromString(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'verified':
      return AccountStatus.verified;
    case 'pending':
      return AccountStatus.pending;
    case 'blocked':
      return AccountStatus.blocked;
    case 'suspended':
      return AccountStatus.suspended;
    default:
      return AccountStatus.active;
  }
}

/// KYC verification level.
enum KycLevel { none, basic, full }

KycLevel kycLevelFromString(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'basic':
      return KycLevel.basic;
    case 'full':
      return KycLevel.full;
    default:
      return KycLevel.none;
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
  final AccountStatus accountStatus;
  final KycLevel kycLevel;
  final String riskLevel; // low, medium, high
  final DateTime? lastLoginAt;
  final DateTime? joinedAt;
  final List<String> tags;
  final String? notes;

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
    this.accountStatus = AccountStatus.active,
    this.kycLevel = KycLevel.none,
    this.riskLevel = 'low',
    this.lastLoginAt,
    this.joinedAt,
    this.tags = const [],
    this.notes,
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
        accountStatus: accountStatusFromString(m['account_status']?.toString()),
        kycLevel: kycLevelFromString(m['kyc_level']?.toString()),
        riskLevel: m['risk_level']?.toString() ?? 'low',
        lastLoginAt: DateTime.tryParse(m['last_login_at']?.toString() ?? ''),
        joinedAt: DateTime.tryParse(m['joined_at']?.toString() ?? ''),
        tags: (m['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        notes: m['notes']?.toString(),
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
        'account_status': accountStatus.name,
        'kyc_level': kycLevel.name,
        'risk_level': riskLevel,
        'last_login_at': lastLoginAt?.toIso8601String(),
        'joined_at': joinedAt?.toIso8601String(),
        'tags': tags,
        'notes': notes,
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
    AccountStatus? accountStatus,
    KycLevel? kycLevel,
    String? riskLevel,
    DateTime? lastLoginAt,
    DateTime? joinedAt,
    List<String>? tags,
    String? notes,
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
        accountStatus: accountStatus ?? this.accountStatus,
        kycLevel: kycLevel ?? this.kycLevel,
        riskLevel: riskLevel ?? this.riskLevel,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        joinedAt: joinedAt ?? this.joinedAt,
        tags: tags ?? this.tags,
        notes: notes ?? this.notes,
      );
}
