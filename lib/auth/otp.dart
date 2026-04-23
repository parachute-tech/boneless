import 'dart:convert';

import 'package:bonless61/auth/login.dart';
import 'package:bonless61/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Otp extends StatefulWidget {
  final String phone;
  final String fullName;
  final String email;
  final String password;
  final String birthDate;

  const Otp({
    super.key,
    required this.phone,
    required this.fullName,
    required this.email,
    required this.password,
    required this.birthDate,
  });

  @override
  State<Otp> createState() => _OtpState();
}

class _OtpState extends State<Otp> {
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  Future<void> _confirmOtp() async {
    final code = otpController.text.trim();

    if (code.length != 6) {
      Get.snackbar(
        'Invalid OTP',
        'Please enter the 6-digit verification code.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/verify-otp'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': widget.phone,
          'code': code,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final registrationToken = data['registration_token']?.toString();

        if (registrationToken == null || registrationToken.isEmpty) {
          Get.snackbar(
            'Verification failed',
            'Registration token was not returned by the server.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        final registerResponse = await http.post(
          Uri.parse('${AppConfig.baseUrl}/auth/register'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'full_name': widget.fullName,
            'email': widget.email,
            'phone': widget.phone,
            'birth_date': widget.birthDate,
            'password': widget.password,
            'password_confirmation': widget.password,
            'registration_token': registrationToken,
          }),
        );

        final Map<String, dynamic> registerData =
            jsonDecode(registerResponse.body);

        if (!mounted) return;

        if (registerResponse.statusCode == 201) {
          Get.snackbar(
            'Account created',
            registerData['message']?.toString() ??
                'Registration completed successfully.',
            snackPosition: SnackPosition.BOTTOM,
          );

          Future.delayed(const Duration(seconds: 1), () {
            Get.offAll(() => const Login());
          });

          return;
        }

        String registerError =
            'Could not complete registration. Please try again.';

        if (registerData['errors'] is Map) {
          final errors = registerData['errors'] as Map;

          if (errors['registration_token'] is List &&
              (errors['registration_token'] as List).isNotEmpty) {
            registerError = errors['registration_token'].first.toString();
          } else if (errors['email'] is List &&
              (errors['email'] as List).isNotEmpty) {
            registerError = errors['email'].first.toString();
          } else if (errors['phone'] is List &&
              (errors['phone'] as List).isNotEmpty) {
            registerError = errors['phone'].first.toString();
          } else if (errors['birth_date'] is List &&
              (errors['birth_date'] as List).isNotEmpty) {
            registerError = errors['birth_date'].first.toString();
          } else if (errors['password'] is List &&
              (errors['password'] as List).isNotEmpty) {
            registerError = errors['password'].first.toString();
          }
        } else if (registerData['message'] != null) {
          registerError = registerData['message'].toString();
        }

        Get.snackbar(
          'Registration failed',
          registerError,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      String errorMessage = 'Could not verify OTP. Please try again.';

      if (data['errors'] is Map &&
          data['errors']['code'] is List &&
          (data['errors']['code'] as List).isNotEmpty) {
        errorMessage = data['errors']['code'].first.toString();
      } else if (data['errors'] is Map &&
          data['errors']['phone'] is List &&
          (data['errors']['phone'] as List).isNotEmpty) {
        errorMessage = data['errors']['phone'].first.toString();
      } else if (data['message'] != null) {
        errorMessage = data['message'].toString();
      }

      Get.snackbar(
        'Verification failed',
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Verify OTP'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Enter the 6-digit code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification code to ${widget.phone}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: const TextStyle(
                    color: Colors.white38,
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: Colors.black,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _confirmOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isLoading ? 'VERIFYING...' : 'CONFIRM OTP'),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}