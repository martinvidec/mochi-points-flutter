import 'enums.dart';

class Reward {
  final String id;
  final String familyId;
  final String createdBy;
  final String name;
  final String? description;
  final String icon;
  final int price;
  final RewardCategory category;
  final int? stock;
  final bool isActive;
  final DateTime createdAt;

  const Reward({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.name,
    this.description,
    required this.icon,
    required this.price,
    required this.category,
    this.stock,
    this.isActive = true,
    required this.createdAt,
  });

  bool get hasLimitedStock => stock != null;
  bool get isAvailable => isActive && (stock == null || stock! > 0);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'createdBy': createdBy,
      'name': name,
      'description': description,
      'icon': icon,
      'price': price,
      'category': category.name,
      'stock': stock,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      createdBy: json['createdBy'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String,
      price: json['price'] as int,
      category: RewardCategory.values.byName(json['category'] as String),
      stock: json['stock'] as int?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Reward copyWith({
    String? id,
    String? familyId,
    String? createdBy,
    String? name,
    String? description,
    String? icon,
    int? price,
    RewardCategory? category,
    int? stock,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Reward(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      createdBy: createdBy ?? this.createdBy,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      price: price ?? this.price,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
