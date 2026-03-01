import 'enums.dart';

class Purchase {
  final String id;
  final String rewardId;
  final String userId;
  final int quantity;
  final int totalPrice;
  final PurchaseStatus status;
  final DateTime purchasedAt;
  final DateTime? redeemedAt;
  final String? redeemedBy;

  const Purchase({
    required this.id,
    required this.rewardId,
    required this.userId,
    this.quantity = 1,
    required this.totalPrice,
    this.status = PurchaseStatus.purchased,
    required this.purchasedAt,
    this.redeemedAt,
    this.redeemedBy,
  });

  bool get isRedeemed => status == PurchaseStatus.redeemed;
  bool get canRedeem => status == PurchaseStatus.purchased;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rewardId': rewardId,
      'userId': userId,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'status': status.name,
      'purchasedAt': purchasedAt.toIso8601String(),
      'redeemedAt': redeemedAt?.toIso8601String(),
      'redeemedBy': redeemedBy,
    };
  }

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] as String,
      rewardId: json['rewardId'] as String,
      userId: json['userId'] as String,
      quantity: json['quantity'] as int,
      totalPrice: json['totalPrice'] as int,
      status: PurchaseStatus.values.byName(json['status'] as String),
      purchasedAt: DateTime.parse(json['purchasedAt'] as String),
      redeemedAt: json['redeemedAt'] != null
          ? DateTime.parse(json['redeemedAt'] as String)
          : null,
      redeemedBy: json['redeemedBy'] as String?,
    );
  }

  Purchase copyWith({
    String? id,
    String? rewardId,
    String? userId,
    int? quantity,
    int? totalPrice,
    PurchaseStatus? status,
    DateTime? purchasedAt,
    DateTime? redeemedAt,
    String? redeemedBy,
  }) {
    return Purchase(
      id: id ?? this.id,
      rewardId: rewardId ?? this.rewardId,
      userId: userId ?? this.userId,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      redeemedBy: redeemedBy ?? this.redeemedBy,
    );
  }
}
