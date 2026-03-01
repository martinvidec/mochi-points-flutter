class PointsAccount {
  final String userId;
  final int balance;
  final int totalEarned;
  final int totalSpent;
  final DateTime lastUpdated;

  const PointsAccount({
    required this.userId,
    this.balance = 0,
    this.totalEarned = 0,
    this.totalSpent = 0,
    required this.lastUpdated,
  });

  bool canAfford(int price) => balance >= price;

  PointsAccount earn(int amount) => copyWith(
        balance: balance + amount,
        totalEarned: totalEarned + amount,
        lastUpdated: DateTime.now(),
      );

  PointsAccount spend(int amount) => copyWith(
        balance: balance - amount,
        totalSpent: totalSpent + amount,
        lastUpdated: DateTime.now(),
      );

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'balance': balance,
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory PointsAccount.fromJson(Map<String, dynamic> json) {
    return PointsAccount(
      userId: json['userId'] as String,
      balance: json['balance'] as int,
      totalEarned: json['totalEarned'] as int,
      totalSpent: json['totalSpent'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  PointsAccount copyWith({
    String? userId,
    int? balance,
    int? totalEarned,
    int? totalSpent,
    DateTime? lastUpdated,
  }) {
    return PointsAccount(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
