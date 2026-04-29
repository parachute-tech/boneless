import 'dart:convert';

import 'package:bonless61/core/theme/app_colors.dart';
import 'package:bonless61/widgets/widgetexport.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool isLoading = true;
  List activeOrders = [];
  List pastOrders = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      setState(() => isLoading = false);
      Get.snackbar(
        'Login required',
        'Please login to view your orders.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final activeResponse = await http.get(
        Uri.parse('http://207.180.254.216/api/orders?status=active'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final pastResponse = await http.get(
        Uri.parse('http://207.180.254.216/api/orders?status=past'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (activeResponse.statusCode == 200 && pastResponse.statusCode == 200) {
        final activeBody = jsonDecode(activeResponse.body);
        final pastBody = jsonDecode(pastResponse.body);

        setState(() {
          activeOrders = activeBody['data'] ?? [];
          pastOrders = pastBody['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        Get.snackbar(
          'Error',
          'Failed to load orders.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      setState(() => isLoading = false);
      Get.snackbar(
        'Error',
        'Something went wrong while loading orders.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _formatItems(dynamic order) {
    final items = order['items'] is List ? order['items'] as List : [];

    if (items.isEmpty) return 'No items';

    return items.map((item) {
      final quantity = item['quantity'] ?? 1;
      final name = item['name'] ?? 'Item';
      return '${quantity}x $name';
    }).join(' · ');
  }

  int _statusStep(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return 0;
      case 'PREPARING':
        return 1;
      case 'OUT_FOR_DELIVERY':
        return 2;
      case 'DELIVERED':
        return 3;
      default:
        return 0;
    }
  }

  String _displayStatus(String status) {
    return status.replaceAll('_', ' ');
  }

  String _displayDate(dynamic order) {
    final value = order['placed_at'] ?? order['created_at'];
    if (value == null) return '';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: fetchOrders,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TRACK ORDER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (activeOrders.isEmpty)
                          const EmptyOrdersCard(
                            message: 'No active orders right now.',
                          )
                        else
                          ...activeOrders.map((order) {
                            final status = order['status']?.toString() ?? 'CONFIRMED';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: TrackOrderCard(
                                orderId: '#${order['order_number'] ?? order['id'] ?? ''}',
                                date: _displayDate(order),
                                itemsText: _formatItems(order),
                                status: _displayStatus(status),
                                currentStep: _statusStep(status),
                              ),
                            );
                          }),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'PAST ORDERS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'VIEW ALL',
                              style: TextStyle(
                                color: AppColors.primaryRed,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (pastOrders.isEmpty)
                          const EmptyOrdersCard(
                            message: 'No past orders yet.',
                          )
                        else
                          ...pastOrders.map((order) {
                            final status = order['status']?.toString() ?? 'DELIVERED';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: PastOrderCard(
                                orderId: '#${order['order_number'] ?? order['id'] ?? ''}',
                                date: _displayDate(order),
                                itemsText: _formatItems(order),
                                status: _displayStatus(status),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class EmptyOrdersCard extends StatelessWidget {
  final String message;

  const EmptyOrdersCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 15,
        ),
      ),
    );
  }
}

class TrackOrderCard extends StatelessWidget {
  final String orderId;
  final String date;
  final String itemsText;
  final String status;
  final int currentStep;

  const TrackOrderCard({
    super.key,
    required this.orderId,
    required this.date,
    required this.itemsText,
    required this.status,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            orderId,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            itemsText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _buildProgressBar(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TRACK ORDER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    const steps = [
      'PLACED',
      'PREPARING',
      'ON THE WAY',
      'DELIVERED',
    ];

    return Column(
      children: [
        Row(
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              final lineIndex = index ~/ 2;
              final isActive = lineIndex < currentStep;
              return Expanded(
                child: Container(
                  height: 3,
                  color: isActive ? AppColors.primaryRed : Colors.white12,
                ),
              );
            }

            final stepIndex = index ~/ 2;
            final isActive = stepIndex <= currentStep;

            return Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppColors.primaryRed : const Color(0xFF2A2A2A),
                border: Border.all(
                  color: isActive ? AppColors.primaryRed : Colors.white24,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            final isActive = index <= currentStep;
            return Expanded(
              child: Text(
                steps[index],
                textAlign: index == 0
                    ? TextAlign.left
                    : index == steps.length - 1
                        ? TextAlign.right
                        : TextAlign.center,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class PastOrderCard extends StatelessWidget {
  final String orderId;
  final String date;
  final String itemsText;
  final String status;

  const PastOrderCard({
    super.key,
    required this.orderId,
    required this.date,
    required this.itemsText,
    required this.status,
  });

  bool get isCanceled => status.toUpperCase() == 'CANCELLED' || status.toUpperCase() == 'CANCELED';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            orderId,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            itemsText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCanceled ? 'ORDER CANCELED' : 'VIEW DETAILS',
                style: TextStyle(
                  color: isCanceled ? Colors.white38 : AppColors.primaryRed,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isCanceled ? const Color(0xFF2A2A2A) : AppColors.primaryRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isCanceled ? Colors.white70 : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}