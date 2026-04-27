import 'dart:convert';

import 'package:bonless61/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  bool isLoading = true;
  bool isSavingAddress = false;
  List addresses = [];

  final recipientNameController = TextEditingController();
  final phoneController = TextEditingController();
  final areaController = TextEditingController();
  final streetController = TextEditingController();
  final buildingController = TextEditingController();
  final floorController = TextEditingController();
  final notesController = TextEditingController();

  String selectedLabel = 'HOME';

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  @override
  void dispose() {
    recipientNameController.dispose();
    phoneController.dispose();
    areaController.dispose();
    streetController.dispose();
    buildingController.dispose();
    floorController.dispose();
    notesController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryRed),
      ),
    );
  }

  Future<void> fetchAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('http://207.180.254.216/api/addresses'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          addresses = body['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        Get.snackbar(
          'Error',
          body['message'] ?? 'Failed to load addresses',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      setState(() => isLoading = false);
      Get.snackbar(
        'Error',
        'Something went wrong',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _clearAddressFields() {
    recipientNameController.clear();
    phoneController.clear();
    areaController.clear();
    streetController.clear();
    buildingController.clear();
    floorController.clear();
    notesController.clear();
    selectedLabel = 'HOME';
  }

  Future<void> addAddress() async {
    if (recipientNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        areaController.text.trim().isEmpty ||
        streetController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing fields',
        'Please fill recipient name, phone, area, and street.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isSavingAddress = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('http://207.180.254.216/api/addresses'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'label': selectedLabel,
          'recipient_name': recipientNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'area': areaController.text.trim(),
          'street': streetController.text.trim(),
          'building': buildingController.text.trim().isEmpty
              ? null
              : buildingController.text.trim(),
          'floor': floorController.text.trim().isEmpty
              ? null
              : floorController.text.trim(),
          'notes': notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          'is_default': addresses.isEmpty,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        Get.back();
        _clearAddressFields();
        await fetchAddresses();
        Get.snackbar(
          'Address added',
          'Your address was added successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryRed,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          body['message'] ?? 'Failed to add address',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Something went wrong',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    if (mounted) {
      setState(() => isSavingAddress = false);
    }
  }

  void showAddAddressDialog() {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Add Address',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedLabel,
                    dropdownColor: const Color(0xFF1E1E1E),
                    decoration: _inputDecoration('Label'),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'HOME', child: Text('HOME')),
                      DropdownMenuItem(value: 'WORK', child: Text('WORK')),
                      DropdownMenuItem(value: 'OTHER', child: Text('OTHER')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedLabel = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: recipientNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Recipient name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Phone'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: areaController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Area'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: streetController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Street'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: buildingController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Building'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: floorController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Floor'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Notes'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isSavingAddress ? null : addAddress,
                      child: isSavingAddress
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Address',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('My Addresses'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryRed,
        onPressed: showAddAddressDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : addresses.isEmpty
              ? const Center(
                  child: Text(
                    'No addresses yet',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final address = addresses[index];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                address['label'] ?? 'ADDRESS',
                                style: const TextStyle(
                                  color: AppColors.primaryRed,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (address['is_default'] == true)
                                const Text(
                                  'Default',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            address['recipient_name'] ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            address['phone'] ?? '',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${address['area'] ?? ''}, ${address['street'] ?? ''}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'Building: ${address['building'] ?? '-'} | Floor: ${address['floor'] ?? '-'}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}