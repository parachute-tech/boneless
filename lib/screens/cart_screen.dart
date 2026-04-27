import 'dart:convert';

import 'package:bonless61/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:bonless61/screens/checkout_page.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool isLoading = true;
  Map<String, dynamic>? cart;
  List items = [];
  final Map<String, String> itemImages = {};

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  Future<void> fetchCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      setState(() => isLoading = false);
      Get.snackbar(
        'Login required',
        'Please login to view your cart.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://207.180.254.216/api/cart'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final data = body['data'] ?? {};
        final cartItems = data['items'] ?? [];

        setState(() {
          cart = Map<String, dynamic>.from(data);
          items = cartItems;
          isLoading = false;
        });

        await fetchCartItemImages(cartItems, token);
      } else {
        setState(() => isLoading = false);
        Get.snackbar(
          'Error',
          body['message']?.toString() ?? 'Failed to load cart.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      setState(() => isLoading = false);
      Get.snackbar(
        'Error',
        'Something went wrong while loading cart.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> fetchCartItemImages(List cartItems, String token) async {
    for (final cartItem in cartItems) {
      if (cartItem is! Map) continue;

      final menuItemId = cartItem['menu_item_id']?.toString();
      if (menuItemId == null || menuItemId.isEmpty) continue;
      if (itemImages.containsKey(menuItemId)) continue;

      try {
        final response = await http.get(
          Uri.parse('http://207.180.254.216/api/menu-items/$menuItemId'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final imageUrl = body['data']?['image_url']?.toString() ?? '';

          if (imageUrl.isNotEmpty && mounted) {
            setState(() {
              itemImages[menuItemId] = imageUrl;
            });
          }
        }
      } catch (_) {}
    }
  }

  Future<void> removeCartItem(String cartItemId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.delete(
        Uri.parse('http://207.180.254.216/api/cart/items/$cartItemId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchCart();
        Get.snackbar(
          'Removed',
          'Item removed from cart.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryRed,
          colorText: Colors.white,
        );
      } else {
        final body = jsonDecode(response.body);
        Get.snackbar(
          'Error',
          body['message']?.toString() ?? 'Could not remove item.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Something went wrong.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = cart?['subtotal_syp']?.toString() ?? '0';
    final itemCount = cart?['item_count']?.toString() ?? items.length.toString();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Cart'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(
                  child: Text(
                    'Your cart is empty',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchCart,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final selectedOptions = item['selected_options'] is List
                          ? item['selected_options'] as List
                          : [];
                      final menuItemId = item['menu_item_id']?.toString() ?? '';
                      final menuItem = item['menu_item'];
                      final menuItemCamel = item['menuItem'];
                      final imageUrl = item['image_url']?.toString() ??
                          item['image']?.toString() ??
                          (menuItem is Map ? menuItem['image_url']?.toString() : null) ??
                          (menuItemCamel is Map ? menuItemCamel['image_url']?.toString() : null) ??
                          itemImages[menuItemId] ??
                          '';

                      return Dismissible(
                        key: ValueKey(item['id']?.toString() ?? index.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        confirmDismiss: (_) async {
                          final id = item['id']?.toString();
                          if (id == null) return false;
                          await removeCartItem(id);
                          return true;
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: imageUrl.startsWith('http')
                                        ? Image.network(
                                            imageUrl,
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
                                        : imageUrl.isNotEmpty
                                            ? Image.asset(
                                                imageUrl,
                                                width: 90,
                                                height: 90,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 90,
                                                height: 90,
                                                color: Colors.white10,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.fastfood,
                                                  color: Colors.white54,
                                                ),
                                              ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name']?.toString() ?? 'Item',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Qty: ${item['quantity'] ?? 1}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item['line_total_syp'] ?? 0} SYP',
                                          style: const TextStyle(
                                            color: AppColors.primaryRed,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      final id = item['id']?.toString();
                                      if (id != null) removeCartItem(id);
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                              if (selectedOptions.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: selectedOptions.map((option) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white12),
                                      ),
                                      child: Text(
                                        option['name']?.toString() ?? 'Option',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              if (item['kitchen_note'] != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Note: ${item['kitchen_note']}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$itemCount items',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '$subtotal SYP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Get.to(() => const CheckoutPage()),
                        child: const Text(
                          'Checkout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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