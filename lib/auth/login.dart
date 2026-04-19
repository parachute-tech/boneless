import 'dart:convert';

import 'package:bonless61/core/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:bonless61/auth/signup.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bonless61/core/theme/app_colors.dart';
import 'package:bonless61/wigets/widgetexport.dart';
import 'package:bonless61/screens/navigator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool isPasswordHidden = true;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  static const String _baseUrl = AppConfig.baseUrl;

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Missing information',
        'Please enter your phone number and password.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final token = data['token']?.toString();

        if (token != null && token.isNotEmpty) {
          await prefs.setString('token', token);
        }

        Get.snackbar(
          'Success',
          data['message']?.toString() ?? 'Logged in successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );

        Get.offAll(() => const AppNavigator());
        return;
      }

      String errorMessage = 'Login failed. Please try again.';

      if (data['errors'] is Map && data['errors']['phone'] is List && (data['errors']['phone'] as List).isNotEmpty) {
        errorMessage = data['errors']['phone'].first.toString();
      } else if (data['message'] != null) {
        errorMessage = data['message'].toString();
      }

      Get.snackbar(
        'Login failed',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (!mounted) return;

      Get.snackbar(
        'Connection error',
        'Could not connect to the server. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04,
            vertical: MediaQuery.of(context).size.height * 0.02,
          ),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              const AuthHeader(
                title: 'BONELESS 61',
                subtitle: 'BOLD FLAVOUR. FAST ORDERING',
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              _buildForm(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Get.to(() => const Signup());
                },
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    children: [
                      TextSpan(text: 'NEW UNIT? '),
                      TextSpan(
                        text: 'JOIN THE FLEET',
                        style: TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(double screenHeight, double screenWidth) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.52,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.025,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(screenWidth * 0.025),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: buildInputField(
              controller: phoneController, //there is an error here 
              label: 'PHONE NUMBER',
              hint: 'PHONE NUMBER',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_iphone_outlined,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: buildInputField(
              controller: passwordController,
              label: 'PASSWORD',
              hint: '••••••••',
              prefixIcon: Icons.lock,
              obscureText: isPasswordHidden,
              isPassword: true,
              onToggle: () {
                setState(() {
                  isPasswordHidden = !isPasswordHidden;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: buildButton(
              text: isLoading ? "SIGNING IN..." : "SIGN IN",
              onTap: isLoading ? null : _login,
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
