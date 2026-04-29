import 'dart:convert';

import 'package:bonless61/core/config/app_config.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bonless61/screens/Item_info.dart';
import 'package:bonless61/widgets/widgetexport.dart';
import 'package:flutter/material.dart';
import 'package:bonless61/core/theme/app_colors.dart';
import 'package:get/route_manager.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Future<List<Map<String, dynamic>>> _menuFuture;
  int _selectedCategoryIndex = 0;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _menuFuture = _fetchMenu();
  }

  Future<List<Map<String, dynamic>>> _fetchMenu() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('No auth token found. Please log in again.');
    }

    final locale = Get.locale?.languageCode ?? 'en';
    final language = locale == 'ar' ? 'ar' : 'en';

    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/menu'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Language': language,
      },
    );

    final Map<String, dynamic> json = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final data = json['data'];
      if (data is List) {
        return data.map((category) => Map<String, dynamic>.from(category as Map)).toList();
      }
      return [];
    }

    if (response.statusCode == 401) {
      await prefs.remove('token');
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception(json['message']?.toString() ?? 'Failed to load menu.');
  }

  Future<void> _retry() async {
    setState(() {
      _menuFuture = _fetchMenu();
    });
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0 SYP';
    return '${value.toString()} SYP';
  }

  String _formatCalories(dynamic value) {
    if (value == null) return 'N/A';
    return '${value.toString()} CAL';
  }

  List<Map<String, dynamic>> _extractItems(Map<String, dynamic> category) {
    final items = category['items'];
    if (items is List) {
      return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return [];
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _menuFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white70, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        snapshot.error.toString().replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _retry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final categories = snapshot.data ?? [];

            if (categories.isEmpty) {
              return const Center(
                child: Text(
                  'No menu items available right now.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final safeIndex = _selectedCategoryIndex >= categories.length ? 0 : _selectedCategoryIndex;
            final selectedCategory = categories[safeIndex];
            final allItems = _extractItems(selectedCategory);
            final normalizedQuery = searchQuery.trim().toLowerCase();
            final items = allItems.where((item) {
              if (normalizedQuery.isEmpty) return true;
              final name = item['name']?.toString().toLowerCase() ?? '';
              final description = item['description']?.toString().toLowerCase() ?? '';
              return name.contains(normalizedQuery) || description.contains(normalizedQuery);
            }).toList();

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    children: [
                                      TextSpan(text: 'BONELESS '),
                                      TextSpan(
                                        text: '61',
                                        style: TextStyle(color: AppColors.primaryRed),
                                      ),
                                      TextSpan(text: ' MENU'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'HEAVY-DUTY FLAVOR FOR THE URBAN\nAPPETITE.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 14,
                                    letterSpacing: 1,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 84,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryRed,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    const SizedBox(width: 18),
                                    const Icon(
                                      Icons.restaurant_menu,
                                      color: Colors.white54,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        selectedCategory['name']?.toString().toUpperCase() ?? 'MENU',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 16,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 66,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white12,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${items.length}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  height: 60,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: categories.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                                    itemBuilder: (context, index) {
                                      final category = categories[index];
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedCategoryIndex = index;
                                          });
                                        },
                                        child: MenuCategoryChip(
                                          label: category['name']?.toString().toUpperCase() ?? 'CATEGORY',
                                          isSelected: index == safeIndex,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: TextField(
                                    controller: searchController,
                                    onChanged: (value) {
                                      setState(() {
                                        searchQuery = value;
                                      });
                                    },
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Search menu',
                                      hintStyle: const TextStyle(color: Colors.white38),
                                      prefixIcon: const Icon(Icons.search, color: Colors.white38),
                                      suffixIcon: searchQuery.isNotEmpty
                                          ? IconButton(
                                              onPressed: () {
                                                searchController.clear();
                                                setState(() {
                                                  searchQuery = '';
                                                });
                                              },
                                              icon: const Icon(Icons.close, color: Colors.white54),
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          searchQuery.isNotEmpty
                              ? 'No menu items match your search.'
                              : 'No items in this category.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )
                    else
                      Column(
                        children: [
                          FeaturedMenuCard(
                            image: items.first['image_url']?.toString() ?? '',
                            title: items.first['name']?.toString() ?? 'ITEM',
                            subtitle: items.first['description']?.toString() ?? '',
                            price: _formatPrice(items.first['price_syp']),
                            calories: _formatCalories(items.first['calories']),
                            onTap: () {
                              Get.to(() => ItemInfo(item: items.first));                            },
                          ),
                          if (items.length > 1) const SizedBox(height: 16),
                          ...items.skip(1).map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: MenuItemCard(
                                image: item['image_url']?.toString() ?? '',
                                title: item['name']?.toString() ?? 'ITEM',
                                subtitle: item['description']?.toString() ?? '',
                                price: _formatPrice(item['price_syp']),
                                item: item,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}