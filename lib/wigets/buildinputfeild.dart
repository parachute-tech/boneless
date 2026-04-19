import 'package:flutter/material.dart';
import 'package:bonless61/core/theme/app_colors.dart';

Widget buildInputField({
    TextEditingController? controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    double inputHeight = 56,
    double labelFontSize = 12,
    double labelSpacing = 10,
    double borderRadius = 30,
    bool obscureText = false,
    bool isPassword = false,
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              color: AppColors.primaryRed,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        SizedBox(height: labelSpacing),
        Container(
          height: inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white12,
            ),
          ),
          child: Center(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: isPassword ? obscureText : false,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Colors.white38,
                ),
                border: InputBorder.none,
                prefixIcon: prefixIcon != null
                    ? Icon(prefixIcon, color: Colors.white54)
                    : null,
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.primaryRed,
                        ),
                        onPressed: onToggle,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }