import 'dart:convert';
import 'package:bonless61/screens/addresses_screen.dart';
import 'package:http/http.dart' as http;
import 'package:bonless61/core/theme/app_colors.dart';
import 'package:bonless61/wigets/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:bonless61/auth/login.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonless61/core/config/app_config.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  String selectedLanguage = 'en';
  bool isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('No auth token found.');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/profile'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> json = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json['data'] as Map);
    }

    if (response.statusCode == 401) {
      await prefs.remove('token');
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception(json['message']?.toString() ?? 'Failed to load profile.');
  }

  Future<void> _retry() async {
    setState(() {
      _profileFuture = _fetchProfile();
    });
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

  Future<void> _saveProfile() async {
    if (fullNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing field',
        'Full name is required.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isSavingProfile = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.patch(
        Uri.parse('${AppConfig.baseUrl}/profile'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'full_name': fullNameController.text.trim(),
          'email': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
          'language': selectedLanguage,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Get.back();
        setState(() {
          _profileFuture = _fetchProfile();
        });
        Get.snackbar(
          'Profile updated',
          'Your profile was updated successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryRed,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          body['message']?.toString() ?? 'Failed to update profile.',
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
      setState(() => isSavingProfile = false);
    }
  }

  void _showEditProfileDialog(Map<String, dynamic> profile) {
    fullNameController.text = profile['full_name']?.toString() ?? '';
    emailController.text = profile['email']?.toString() ?? '';
    selectedLanguage = profile['language']?.toString() == 'ar' ? 'ar' : 'en';

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
                        'Edit Profile',
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
                  TextField(
                    controller: fullNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Full name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Email'),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.white54, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Phone: ${profile['phone'] ?? 'N/A'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.white54, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Birth date: ${profile['birth_date'] ?? 'N/A'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12,),
                  DropdownButtonFormField<String>(
                    value: selectedLanguage,
                    dropdownColor: const Color(0xFF1E1E1E),
                    decoration: _inputDecoration('Language'),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'ar', child: Text('Arabic')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedLanguage = value);
                    },
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
                      onPressed: isSavingProfile ? null : _saveProfile,
                      child: isSavingProfile
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Profile',
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
      appBar: const TopBar(),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
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

            final profile = snapshot.data!;
            final fullName = (profile['full_name']?.toString().trim().isNotEmpty ?? false)
                ? profile['full_name'].toString()
                : 'Guest User';
            final email = (profile['email']?.toString().trim().isNotEmpty ?? false)
                ? profile['email'].toString()
                : 'No email available';
            final phone = (profile['phone']?.toString().trim().isNotEmpty ?? false)
                ? profile['phone'].toString()
                : 'No phone available';
            final loyaltyTier = profile['loyalty_tier'];
            final tierName = loyaltyTier is Map && loyaltyTier['name'] != null
                ? loyaltyTier['name'].toString()
                : 'MEMBER';

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ProfileCard(
                      name: fullName.toUpperCase(),
                      email: email,
                      phone: phone,
                      tier: tierName.toUpperCase(),
                      onEdit: () => _showEditProfileDialog(profile),
                    ),
                    const SizedBox(height: 20),
                    const PointsCard(
                      points: 25,
                      progress: 0.62,
                      remainingText: '15 PTS UNTIL FREE LOADED FRIES',
                    ),
                    const SizedBox(height: 20),
                    const ProfileActionsGrid(),
                    const SizedBox(height: 30),
                    const LogoutButton(),
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

class ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String tier;
  final VoidCallback onEdit;

  const ProfileCard({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.tier,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primaryRed, width: 2),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tier,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: onEdit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'EDIT\nPROFILE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PointsCard extends StatelessWidget {
  final int points;
  final double progress; // 0 -> 1
  final String remainingText;

  const PointsCard({
    super.key,
    required this.points,
    required this.progress,
    required this.remainingText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL REWARDS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              Icon(Icons.confirmation_number, color: AppColors.primaryRed),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'POINTS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            remainingText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'REDEEM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'HOW TO EARN',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
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

class ProfileActionsGrid extends StatelessWidget {
  const ProfileActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: const ProfileActionCard(
                icon: Icons.restaurant,
                title: 'MY\nORDERS',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: GestureDetector(
                onTap: () => Get.to(AddressesScreen()),
                child: const ProfileActionCard(
                  icon: Icons.location_on_outlined,
                  title: 'SAVED\nADDRESSES',
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: const ProfileActionCard(
                icon: Icons.credit_card,
                title: 'PAYMENT\nMETHODS',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: const ProfileActionCard(
                icon: Icons.history,
                title: 'REWARDS\nHISTORY',
              ),
            ),
          ],
        );
      },
    );
  }
}

class ProfileActionCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const ProfileActionCard({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 136,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    if (!context.mounted) return;

    Get.offAll(() => const Login());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await _logout(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout, color: AppColors.primaryRed, size: 20),
            SizedBox(width: 8),
            Text(
              'LOG OUT',
              style: TextStyle(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}