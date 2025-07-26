import 'package:flutter/material.dart';

class Category {
  final int id;
  final String name;
  final String description;
  final IconData icon;
  final bool isReasoning;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isReasoning,
  });
}
