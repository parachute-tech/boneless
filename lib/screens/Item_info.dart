import 'dart:convert';

import 'package:bonless61/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ItemInfo extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemInfo({super.key, required this.item});

  @override
  State<ItemInfo> createState() => _ItemInfoState();
}

class _ItemInfoState extends State<ItemInfo> {
  late final List<String> images;
  Map<String, dynamic>? itemDetails;
  bool isLoading = true;
  bool isAddingToCart = false;
  int quantity = 1;
  final kitchenNoteController = TextEditingController();
  final Set<String> selectedOptionIds = {};

  Map<String, dynamic> get currentItem => itemDetails ?? widget.item;

  @override
  void initState() {
    super.initState();
    final imageUrl = widget.item['image_url']?.toString() ?? '';
    images = imageUrl.isNotEmpty
        ? [imageUrl, imageUrl, imageUrl]
        : ['assets/box.png', 'assets/box.png', 'assets/box.png'];
    fetchItemDetails();
  }

  @override
  void dispose() {
    kitchenNoteController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchItemDetails() async {
    final token = await _getToken();
    final itemId = widget.item['id']?.toString();

    if (itemId == null || itemId.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://207.180.254.216/api/menu-items/$itemId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          itemDetails = body['data'] ?? widget.item;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  void _toggleOption(Map<String, dynamic> group, Map<String, dynamic> option) {
    final optionId = option['id']?.toString();
    if (optionId == null) return;

    final multiSelect = group['multi_select'] == true;
    final options = group['options'] is List ? group['options'] as List : [];

    setState(() {
      if (multiSelect) {
        if (selectedOptionIds.contains(optionId)) {
          selectedOptionIds.remove(optionId);
        } else {
          selectedOptionIds.add(optionId);
        }
        return;
      }

      for (final item in options) {
        final id = item['id']?.toString();
        if (id != null) selectedOptionIds.remove(id);
      }
      selectedOptionIds.add(optionId);
    });
  }

  bool _hasMissingRequiredOptions() {
    final groups = currentItem['option_groups'] is List
        ? currentItem['option_groups'] as List
        : [];

    for (final group in groups) {
      if (group is! Map<String, dynamic>) continue;
      if (group['is_required'] != true) continue;

      final options = group['options'] is List ? group['options'] as List : [];
      final hasSelection = options.any((option) {
        final optionId = option['id']?.toString();
        return optionId != null && selectedOptionIds.contains(optionId);
      });

      if (!hasSelection) return true;
    }

    return false;
  }

  Future<void> addToCart() async {
    if (_hasMissingRequiredOptions()) {
      Get.snackbar(
        'Required option',
        'Please select all required options.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final token = await _getToken();
    final menuItemId = currentItem['id']?.toString();

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

    setState(() => isAddingToCart = true);

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
          'quantity': quantity,
          'kitchen_note': kitchenNoteController.text.trim().isEmpty
              ? null
              : kitchenNoteController.text.trim(),
          'option_ids': selectedOptionIds.toList(),
        }),
      );

      Map<String, dynamic> body = {};
      if (response.body.isNotEmpty) {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          'Added to cart',
          '${currentItem['name'] ?? 'Item'} added to your cart.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryRed,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          body['message']?.toString() ?? 'Could not add item to cart.',
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
      setState(() => isAddingToCart = false);
    }
  }

  int _basePrice() {
    return int.tryParse(currentItem['price_syp']?.toString() ?? '0') ?? 0;
  }

  int _selectedOptionsTotal() {
    final groups = currentItem['option_groups'] is List
        ? currentItem['option_groups'] as List
        : [];

    int total = 0;
    for (final group in groups) {
      if (group is! Map<String, dynamic>) continue;
      final options = group['options'] is List ? group['options'] as List : [];
      for (final option in options) {
        final optionId = option['id']?.toString();
        if (optionId != null && selectedOptionIds.contains(optionId)) {
          total += int.tryParse(option['extra_price_syp']?.toString() ?? '0') ?? 0;
        }
      }
    }
    return total;
  }

  int _totalPrice() {
    return (_basePrice() + _selectedOptionsTotal()) * quantity;
  }

  @override
  Widget build(BuildContext context) {
    final itemName = currentItem['name']?.toString() ?? 'Item';
    final description = currentItem['description']?.toString() ?? '';
    final calories = currentItem['calories'];
    final optionGroups = currentItem['option_groups'] is List
        ? currentItem['option_groups'] as List
        : [];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          itemName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      bottomNavigationBar: AddToCartBar(
        totalPrice: _totalPrice(),
        isLoading: isAddingToCart,
        onPressed: addToCart,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ImageSlider(images: images),
                    const SizedBox(height: 20),
                    ItemHeader(
                      name: itemName,
                      description: description,
                      price: _basePrice(),
                      calories: calories,
                    ),
                    const SizedBox(height: 20),
                    QuantitySelector(
                      quantity: quantity,
                      onDecrease: () {
                        if (quantity == 1) return;
                        setState(() => quantity--);
                      },
                      onIncrease: () => setState(() => quantity++),
                    ),
                    const SizedBox(height: 20),
                    if (optionGroups.isNotEmpty) ...[
                      const SectionTitle(title: 'Additions'),
                      const SizedBox(height: 12),
                      ...optionGroups.map((group) {
                        if (group is! Map<String, dynamic>) {
                          return const SizedBox.shrink();
                        }

                        return OptionGroupCard(
                          group: group,
                          selectedOptionIds: selectedOptionIds,
                          onOptionTap: _toggleOption,
                        );
                      }),
                    ],
                    const SizedBox(height: 8),
                    const SectionTitle(title: 'Kitchen note'),
                    const SizedBox(height: 12),
                    KitchenNoteField(controller: kitchenNoteController),
                  ],
                ),
              ),
      ),
    );
  }
}

class ItemHeader extends StatelessWidget {
  final String name;
  final String description;
  final int price;
  final dynamic calories;

  const ItemHeader({
    super.key,
    required this.name,
    required this.description,
    required this.price,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              '$price SYP',
              style: const TextStyle(
                color: AppColors.primaryRed,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              calories != null ? '$calories CAL' : 'N/A',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SectionTitle(title: 'Quantity'),
        const Spacer(),
        QuantityButton(icon: Icons.remove, onTap: onDecrease),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            quantity.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        QuantityButton(icon: Icons.add, onTap: onIncrease),
      ],
    );
  }
}

class QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const QuantityButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class OptionGroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final Set<String> selectedOptionIds;
  final void Function(Map<String, dynamic> group, Map<String, dynamic> option)
      onOptionTap;

  const OptionGroupCard({
    super.key,
    required this.group,
    required this.selectedOptionIds,
    required this.onOptionTap,
  });

  @override
  Widget build(BuildContext context) {
    final options = group['options'] is List ? group['options'] as List : [];
    final title = group['label']?.toString() ?? 'Options';
    final isRequired = group['is_required'] == true;
    final isMultiSelect = group['multi_select'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                isRequired
                    ? 'Required'
                    : isMultiSelect
                        ? 'Optional'
                        : 'Choose one',
                style: TextStyle(
                  color: isRequired ? AppColors.primaryRed : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...options.map((option) {
            if (option is! Map<String, dynamic>) {
              return const SizedBox.shrink();
            }

            final optionId = option['id']?.toString() ?? '';
            final isSelected = selectedOptionIds.contains(optionId);

            return OptionTile(
              option: option,
              isSelected: isSelected,
              isMultiSelect: isMultiSelect,
              onTap: () => onOptionTap(group, option),
            );
          }),
        ],
      ),
    );
  }
}

class OptionTile extends StatelessWidget {
  final Map<String, dynamic> option;
  final bool isSelected;
  final bool isMultiSelect;
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.isMultiSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = option['name']?.toString() ?? 'Option';
    final extraPrice = int.tryParse(option['extra_price_syp']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed.withOpacity(0.18) : Colors.black,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isMultiSelect
                  ? isSelected
                      ? Icons.check_box
                      : Icons.check_box_outline_blank
                  : isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryRed : Colors.white54,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              extraPrice == 0 ? 'Free' : '+$extraPrice SYP',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KitchenNoteField extends StatelessWidget {
  final TextEditingController controller;

  const KitchenNoteField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Example: no onions, extra crispy...',
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
    );
  }
}

class AddToCartBar extends StatelessWidget {
  final int totalPrice;
  final bool isLoading;
  final VoidCallback onPressed;

  const AddToCartBar({
    super.key,
    required this.totalPrice,
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
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Add to Cart • $totalPrice SYP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class ImageSlider extends StatefulWidget {
  final List<String> images;

  const ImageSlider({
    super.key,
    required this.images,
  });

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: widget.images[index].startsWith('http')
                    ? Image.network(
                        widget.images[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white10,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.fastfood,
                            color: Colors.white54,
                            size: 42,
                          ),
                        ),
                      )
                    : Image.asset(
                        widget.images[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              );
            },
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: currentIndex == index ? 10 : 8,
                  height: currentIndex == index ? 10 : 8,
                  decoration: BoxDecoration(
                    color: currentIndex == index ? Colors.white : Colors.white38,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}