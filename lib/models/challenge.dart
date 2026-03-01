import 'package:flutter/material.dart';

// @deprecated Use Quest model from quest.dart instead.
// This class will be removed in a future version.
class Challenge {
  final String id;
  final String name;
  final IconData icon;
  final double reward;

  Challenge({required this.id, required this.name, required this.icon, required this.reward});
}
