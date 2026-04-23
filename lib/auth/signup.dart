import 'dart:convert';

import 'package:bonless61/core/config/app_config.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:bonless61/core/theme/app_colors.dart';
import 'package:bonless61/wigets/widgetexport.dart';
import 'package:flutter/material.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:bonless61/auth/otp.dart';
import 'package:country_picker/country_picker.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool isPasswordHidden = true;
  bool agree = false;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String birthDate = '';
  bool isLoading = false;

  Country selectedCountry = Country.parse('SY');

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    String rawPhone = phoneController.text.trim();
    while (rawPhone.startsWith('0')) {
      rawPhone = rawPhone.substring(1);
    }
    final phone = '+${selectedCountry.phoneCode}$rawPhone';

    if (phone.isEmpty) {
      Get.snackbar(
        'Phone number required',
        'Please enter your phone number to receive the OTP.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!agree) {
      Get.snackbar(
        'Terms required',
        'Please agree to the Terms & Conditions and Privacy Policy.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/request-otp'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phone,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final expiresIn = data['expires_in_seconds']?.toString() ?? '300';

        Get.snackbar(
          'OTP sent',
          'A verification code was sent to $phone. It expires in $expiresIn seconds.',
          snackPosition: SnackPosition.BOTTOM,
        );

        Get.to(
          () => Otp(
            phone: phone,
            fullName: fullNameController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            birthDate: birthDate,
          ),
        );
        return;
      }

      String errorMessage = 'Could not send OTP. Please try again.';

      if (data['errors'] is Map && data['errors']['phone'] is List && (data['errors']['phone'] as List).isNotEmpty) {
        errorMessage = data['errors']['phone'].first.toString();
      } else if (data['message'] != null) {
        errorMessage = data['message'].toString();
      }

      Get.snackbar(
        'OTP failed',
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final compact = screenHeight < 760;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.045,
                vertical: compact ? 10 : 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: compact ? 10 : 16),
                    Transform.scale(
                      scale: compact ? 0.9 : 1,
                      child: const AuthHeader(
                        title: "JOIN BONLESS 61",
                        subtitle:
                            "CREATE YOUR ACCOUNT TO ORDER\nFASTER AND EARN REWARDS",
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 20),
                    _buildForm(
                      screenWidth,
                      screenHeight,
                      compact: compact,
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

  Widget _buildForm(
    double screenWidth,
    double screenHeight, {
    required bool compact,
  }) {
    final fieldHeight = compact ? 46.0 : 60.0;
    final labelFontSize = compact ? 11.0 : 13.0;
    final labelSpacing = compact ? 6.0 : 10.0;
    final fieldRadius = compact ? 24.0 : 32.0;
    final cardRadius = compact ? 12.0 : 18.0;
    final fieldGap = compact ? 10.0 : 16.0;
    final buttonGap = compact ? 14.0 : 22.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 22,
        vertical: compact ? 14 : 22,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildInputField(
            controller: fullNameController,
            label: 'FULL NAME',
            hint: 'FULL NAME',
            prefixIcon: Icons.person,
            inputHeight: fieldHeight,
            labelFontSize: labelFontSize,
            labelSpacing: labelSpacing,
            borderRadius: fieldRadius,
          ),
          SizedBox(height: fieldGap),
          _buildBirthDateField(
            fieldHeight: fieldHeight,
            labelFontSize: labelFontSize,
            labelSpacing: labelSpacing,
            fieldRadius: fieldRadius,
          ),
          SizedBox(height: fieldGap),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    color: AppColors.primaryRed,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PHONE NUMBER',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: labelSpacing),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      showCountryPicker(
                        context: context,
                        showPhoneCode: true,
                        favorite: const ['SY'],
                        countryListTheme: CountryListThemeData(
                          backgroundColor: Colors.black,
                          textStyle: const TextStyle(color: Colors.white),
                          bottomSheetHeight: MediaQuery.of(context).size.height * 0.85,
                          inputDecoration: InputDecoration(
                            hintText: 'Search country',
                            hintStyle: const TextStyle(color: Colors.white54),
                            prefixIcon: const Icon(Icons.search, color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF1E1E1E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        onSelect: (Country country) {
                          setState(() {
                            selectedCountry = country;
                          });
                        },
                      );
                    },
                    child: Container(
                      height: fieldHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(fieldRadius),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedCountry.flagEmoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${selectedCountry.phoneCode}',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_drop_down, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: buildInputField(
                      controller: phoneController,
                      label: '',
                      hint: 'PHONE NUMBER',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone,
                      inputHeight: fieldHeight,
                      labelFontSize: labelFontSize,
                      labelSpacing: 0,
                      borderRadius: fieldRadius,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: fieldGap),
          buildInputField(
            controller: emailController,
            label: 'EMAIL ADDRESS',
            hint: 'EMAIL ADDRESS',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email,
            inputHeight: fieldHeight,
            labelFontSize: labelFontSize,
            labelSpacing: labelSpacing,
            borderRadius: fieldRadius,
          ),
          SizedBox(height: fieldGap),
          buildInputField(
            controller: passwordController,
            label: 'PASSWORD',
            hint: '••••••••',
            prefixIcon: Icons.lock,
            isPassword: true,
            obscureText: isPasswordHidden,
            onToggle: () {
              setState(() {
                isPasswordHidden = !isPasswordHidden;
              });
            },
            inputHeight: fieldHeight,
            labelFontSize: labelFontSize,
            labelSpacing: labelSpacing,
            borderRadius: fieldRadius,
          ),
          SizedBox(height: buttonGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.scale(
                scale: compact ? 0.82 : 0.95,
                child: Checkbox(
                  value: agree,
                  onChanged: (v) {
                    setState(() {
                      agree = v ?? false;
                    });
                  },
                  activeColor: AppColors.primaryRed,
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
              SizedBox(width: compact ? 4 : 8),
              Flexible(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: compact ? 12 : 14,
                    ),
                    children: const [
                      TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(color: AppColors.primaryRed),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(color: AppColors.primaryRed),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 12),
          buildButton(
            text: isLoading ? 'SENDING OTP...' : 'CREATE ACCOUNT',
            onTap: isLoading ? null : _requestOtp,
            height: compact ? 48 : 60,
            fontSize: compact ? 14 : 16,
            borderRadius: compact ? 22 : 28,
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: CircularProgressIndicator(),
            ),
          SizedBox(height: compact ? 6 : 12),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: compact ? 12 : 14,
                ),
                children: const [
                  TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'SIGN IN',
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
    );
  }

  Widget _buildBirthDateField({
    required double fieldHeight,
    required double labelFontSize,
    required double labelSpacing,
    required double fieldRadius,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              color: AppColors.primaryRed,
            ),
            const SizedBox(width: 8),
            Text(
              'BIRTH DATE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        SizedBox(height: labelSpacing),
        Container(
          height: fieldHeight,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(fieldRadius),
            border: Border.all(
              color: Colors.white12,
            ),
          ),
          child: Center(
            child: DateTimePicker(
              type: DateTimePickerType.date,
              dateMask: 'dd/MM/yyyy',
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              initialValue: DateTime(
                DateTime.now().year - 16,
                DateTime.now().month,
                DateTime.now().day,
              ).toIso8601String(),
              onChanged: (value) {
                birthDate = value;
              },
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'DD/MM/YYYY',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.calendar_today, color: Colors.white54),
              ),
            ),
          ),
        ),
      ],
    );
  }
}