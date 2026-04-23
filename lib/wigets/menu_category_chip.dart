import 'package:bonless61/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MenuCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const MenuCategoryChip({
    super.key,
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryRed : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}