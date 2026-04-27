import 'dart:convert';

import 'package:bonless61/core/theme/app_colors.dart';
import 'package:bonless61/screens/orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool isLoading = true;
  bool isPlacingOrder = false;

  Map<String, dynamic>? cart;
  List cartItems = [];
  List addresses = [];
  List branches = [];

  String orderType = 'DELIVERY';
  String? selectedAddressId;
  String? selectedBranchId;

  final deliveryNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCheckoutData();
  }

  @override
  void dispose() {
    deliveryNotesController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> loadCheckoutData() async {
    setState(() => isLoading = true);

    final token = await _getToken();

    if (token == null || token.isEmpty) {
      setState(() => isLoading = false);
      Get.snackbar(
        'Login required',
        'Please login before checkout.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    await Future.wait([
      fetchCart(token),
      fetchAddresses(token),
      fetchBranches(),
    ]);

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchCart(String token) async {
    try {
      final response = await http.get(
        Uri.parse('http://207.180.254.216/api/cart'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? {};

        if (!mounted) return;
        setState(() {
          cart = Map<String, dynamic>.from(data);
          cartItems = data['items'] ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> fetchAddresses(String token) async {
    try {
      final response = await http.get(
        Uri.parse('http://207.180.254.216/api/addresses'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? [];

        if (!mounted) return;
        setState(() {
          addresses = data;
          if (addresses.isNotEmpty) {
            final defaultAddress = addresses.firstWhere(
              (address) => address['is_default'] == true,
              orElse: () => addresses.first,
            );
            selectedAddressId = defaultAddress['id']?.toString();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> fetchBranches() async {
    try {
      final response = await http.get(
        Uri.parse('http://207.180.254.216/api/branches'),
        headers: const {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? [];

        if (!mounted) return;
        setState(() {
          branches = data;
          if (branches.isNotEmpty) {
            selectedBranchId = branches.first['id']?.toString();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> placeOrder() async {
    if (cartItems.isEmpty) {
      Get.snackbar(
        'Empty cart',
        'Please add items to your cart before checkout.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (selectedBranchId == null) {
      Get.snackbar(
        'Missing branch',
        'Please select a branch.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (orderType == 'DELIVERY' && selectedAddressId == null) {
      Get.snackbar(
        'Missing address',
        'Please select a delivery address.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    setState(() => isPlacingOrder = true);

    try {
      final response = await http.post(
        Uri.parse('http://207.180.254.216/api/orders'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'branch_id': selectedBranchId,
          'type': orderType,
          'address_id': orderType == 'DELIVERY' ? selectedAddressId : null,
          'delivery_notes': deliveryNotesController.text.trim().isEmpty
              ? null
              : deliveryNotesController.text.trim(),
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        Get.snackbar(
          'Order placed',
          'Your order has been placed successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryRed,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        Future.delayed(const Duration(seconds: 2), () {
          Get.offAll(() => const OrdersScreen());
        });
      } else {
        Get.snackbar(
          'Error',
          body['message']?.toString() ?? 'Could not place order.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    if (mounted) {
      setState(() => isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = cart?['subtotal_syp']?.toString() ?? '0';
    final itemCount = cart?['item_count']?.toString() ?? cartItems.length.toString();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Checkout'),
      ),
      bottomNavigationBar: isLoading || cartItems.isEmpty
          ? null
          : CheckoutBottomBar(
              itemCount: itemCount,
              subtotal: subtotal,
              isLoading: isPlacingOrder,
              onPressed: placeOrder,
            ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? const EmptyCheckoutState()
              : RefreshIndicator(
                  onRefresh: loadCheckoutData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      CheckoutSection(
                        title: 'Order Type',
                        child: Row(
                          children: [
                            Expanded(
                              child: OrderTypeButton(
                                title: 'Delivery',
                                icon: Icons.delivery_dining,
                                isSelected: orderType == 'DELIVERY',
                                onTap: () => setState(() => orderType = 'DELIVERY'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OrderTypeButton(
                                title: 'Pickup',
                                icon: Icons.shopping_bag_outlined,
                                isSelected: orderType == 'PICKUP',
                                onTap: () => setState(() => orderType = 'PICKUP'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CheckoutSection(
                        title: 'Branch',
                        child: branches.isEmpty
                            ? const EmptySmallMessage(message: 'No branches available')
                            : Column(
                                children: branches.map((branch) {
                                  final branchId = branch['id']?.toString();
                                  return SelectableCheckoutCard(
                                    isSelected: selectedBranchId == branchId,
                                    title: branch['name']?.toString() ?? 'Branch',
                                    subtitle:
                                        '${branch['city'] ?? ''} • ${branch['address'] ?? ''}',
                                    icon: Icons.storefront,
                                    onTap: () => setState(() {
                                      selectedBranchId = branchId;
                                    }),
                                  );
                                }).toList(),
                              ),
                      ),
                      if (orderType == 'DELIVERY') ...[
                        const SizedBox(height: 16),
                        CheckoutSection(
                          title: 'Delivery Address',
                          child: addresses.isEmpty
                              ? const EmptySmallMessage(
                                  message: 'No addresses found. Add one from profile.',
                                )
                              : Column(
                                  children: addresses.map((address) {
                                    final addressId = address['id']?.toString();
                                    return SelectableCheckoutCard(
                                      isSelected: selectedAddressId == addressId,
                                      title:
                                          '${address['label'] ?? 'ADDRESS'} • ${address['recipient_name'] ?? ''}',
                                      subtitle:
                                          '${address['area'] ?? ''}, ${address['street'] ?? ''}',
                                      icon: Icons.location_on_outlined,
                                      trailing: address['is_default'] == true
                                          ? 'Default'
                                          : null,
                                      onTap: () => setState(() {
                                        selectedAddressId = addressId;
                                      }),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      CheckoutSection(
                        title: 'Delivery Notes',
                        child: TextField(
                          controller: deliveryNotesController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Example: ring the bell, 3rd floor...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: const Color(0xFF1E1E1E),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.primaryRed),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CheckoutSection(
                        title: 'Cart Summary',
                        child: Column(
                          children: [
                            ...cartItems.map((item) {
                              return CartSummaryTile(item: item);
                            }),
                            const Divider(color: Colors.white12),
                            SummaryRow(label: 'Items', value: itemCount),
                            const SizedBox(height: 8),
                            SummaryRow(label: 'Subtotal', value: '$subtotal SYP'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class CheckoutSection extends StatelessWidget {
  final String title;
  final Widget child;

  const CheckoutSection({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class OrderTypeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const OrderTypeButton({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : Colors.white12,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectableCheckoutCard extends StatelessWidget {
  final bool isSelected;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? trailing;
  final VoidCallback onTap;

  const SelectableCheckoutCard({
    super.key,
    required this.isSelected,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryRed : Colors.white54,
            ),
            const SizedBox(width: 10),
            Icon(icon, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CartSummaryTile extends StatelessWidget {
  final dynamic item;

  const CartSummaryTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item['quantity'] ?? 1}x ${item['name'] ?? 'Item'}',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            '${item['line_total_syp'] ?? 0} SYP',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const SummaryRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class EmptySmallMessage extends StatelessWidget {
  final String message;

  const EmptySmallMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}

class EmptyCheckoutState extends StatelessWidget {
  const EmptyCheckoutState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Your cart is empty',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class CheckoutBottomBar extends StatelessWidget {
  final String itemCount;
  final String subtotal;
  final bool isLoading;
  final VoidCallback onPressed;

  const CheckoutBottomBar({
    super.key,
    required this.itemCount,
    required this.subtotal,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                onPressed: isLoading ? null : onPressed,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Place Order',
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
    );
  }
}