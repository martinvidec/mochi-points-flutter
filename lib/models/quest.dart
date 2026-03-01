import 'package:flutter/material.dart';
import 'enums.dart';
import '../theme/app_colors.dart';

class Quest {
  final String id;
  final String familyId;
  final String createdBy;
  final String name;
  final String? description;
  final String icon;
  final QuestType type;
  final QuestRarity rarity;
  final int rewardPoints;
  final int rewardXP;
  final List<String> assignedTo;
  final DateTime? deadline;
  final bool isActive;
  final DateTime createdAt;
  final int? targetCount;
  final String? unit;

  const Quest({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.name,
    this.description,
    required this.icon,
    required this.type,
    required this.rarity,
    required this.rewardPoints,
    required this.rewardXP,
    this.assignedTo = const [],
    this.deadline,
    this.isActive = true,
    required this.createdAt,
    this.targetCount,
    this.unit,
  });

  bool get isSeries => type == QuestType.series;
  bool get hasDeadline => deadline != null;
  bool get isExpired => deadline != null && DateTime.now().isAfter(deadline!);

  Color get rarityColor {
    switch (rarity) {
      case QuestRarity.common:
        return AppColors.rarityCommon;
      case QuestRarity.rare:
        return AppColors.rarityRare;
      case QuestRarity.epic:
        return AppColors.rarityEpic;
      case QuestRarity.legendary:
        return AppColors.rarityLegendary;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'createdBy': createdBy,
      'name': name,
      'description': description,
      'icon': icon,
      'type': type.name,
      'rarity': rarity.name,
      'rewardPoints': rewardPoints,
      'rewardXP': rewardXP,
      'assignedTo': assignedTo,
      'deadline': deadline?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'targetCount': targetCount,
      'unit': unit,
    };
  }

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      createdBy: json['createdBy'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String,
      type: QuestType.values.byName(json['type'] as String),
      rarity: QuestRarity.values.byName(json['rarity'] as String),
      rewardPoints: json['rewardPoints'] as int,
      rewardXP: json['rewardXP'] as int,
      assignedTo: List<String>.from(json['assignedTo'] as List),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      targetCount: json['targetCount'] as int?,
      unit: json['unit'] as String?,
    );
  }

  Quest copyWith({
    String? id,
    String? familyId,
    String? createdBy,
    String? name,
    String? description,
    String? icon,
    QuestType? type,
    QuestRarity? rarity,
    int? rewardPoints,
    int? rewardXP,
    List<String>? assignedTo,
    DateTime? deadline,
    bool? isActive,
    DateTime? createdAt,
    int? targetCount,
    String? unit,
  }) {
    return Quest(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      createdBy: createdBy ?? this.createdBy,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      rewardXP: rewardXP ?? this.rewardXP,
      assignedTo: assignedTo ?? this.assignedTo,
      deadline: deadline ?? this.deadline,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      targetCount: targetCount ?? this.targetCount,
      unit: unit ?? this.unit,
    );
  }
}

class QuestInstance {
  final String id;
  final String questId;
  final String childId;
  final QuestStatus status;
  final int progress;
  final int target;
  final int currentStreak;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime createdAt;

  const QuestInstance({
    required this.id,
    required this.questId,
    required this.childId,
    this.status = QuestStatus.available,
    this.progress = 0,
    this.target = 1,
    this.currentStreak = 0,
    this.startedAt,
    this.completedAt,
    this.approvedAt,
    this.approvedBy,
    required this.createdAt,
  });

  double get progressPercent => target > 0 ? progress / target : 0;
  bool get isComplete => progress >= target;
  bool get isPending => status == QuestStatus.pendingApproval;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questId': questId,
      'childId': childId,
      'status': status.name,
      'progress': progress,
      'target': target,
      'currentStreak': currentStreak,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QuestInstance.fromJson(Map<String, dynamic> json) {
    return QuestInstance(
      id: json['id'] as String,
      questId: json['questId'] as String,
      childId: json['childId'] as String,
      status: QuestStatus.values.byName(json['status'] as String),
      progress: json['progress'] as int,
      target: json['target'] as int,
      currentStreak: json['currentStreak'] as int,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      approvedBy: json['approvedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  QuestInstance copyWith({
    String? id,
    String? questId,
    String? childId,
    QuestStatus? status,
    int? progress,
    int? target,
    int? currentStreak,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? approvedAt,
    String? approvedBy,
    DateTime? createdAt,
  }) {
    return QuestInstance(
      id: id ?? this.id,
      questId: questId ?? this.questId,
      childId: childId ?? this.childId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      currentStreak: currentStreak ?? this.currentStreak,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
