import 'package:flutter/material.dart';
import 'package:bonless61/core/theme/app_colors.dart';

Widget buildButton({
  required String text,
  VoidCallback? onTap,
  double height = 65,
  double fontSize = 16,
  double borderRadius = 30,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: fontSize,
          ),
        ),
      ),
    ),
  );
}
