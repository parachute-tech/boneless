import 'dart:convert';

import 'package:bonless61/core/theme/app_colors.dart';
import 'package:bonless61/screens/Item_info.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MenuItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String image;
  final Map<String, dynamic> item;

  const MenuItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.image,
    required this.item,
  });

  Future<void> _quickAddToCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final menuItemId = item['id']?.toString();

    if (token == null || token.isEmpty) {
      Get.snackbar(
        'Login required',
        'Please login before adding items to cart.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (menuItemId == null || menuItemId.isEmpty) {
      Get.snackbar(
        'Error',
        'Menu item id is missing.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://207.180.254.216/api/cart/items'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'menu_item_id': menuItemId,
          'quantity': 1,
          'kitchen_note': null,
          'option_ids': <String>[],
        }),
      );

      Map<String, dynamic> responseBody = {};
      if (response.body.isNotEmpty) {
        responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          'Added to cart',
          '$title added to your cart.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryRed,
          colorText: Colors.white,
        );
        return;
      }

      Get.snackbar(
        'Error',
        responseBody['message']?.toString() ?? 'Could not add item to cart.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: GestureDetector(
        onTap: () {
          Get.to(() => ItemInfo(item: item));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: image.startsWith('http')
                    ? Image.network(
                        image,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.white10,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.fastfood,
                            color: Colors.white54,
                          ),
                        ),
                      )
                    : Image.asset(
                        image,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      price,
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _quickAddToCart,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}