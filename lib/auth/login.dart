import 'package:bonless61/auth/signup.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bonless61/core/theme/app_colors.dart';
import 'package:bonless61/wigets/widgetexport.dart';
import 'package:bonless61/screens/navigator.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool isPasswordHidden = true;

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
              label: 'PHONE NUMBER',
              hint: 'PHONE NUMBER',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_iphone_outlined,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: buildInputField(
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
              text: "SIGN IN",
              onTap: () {
                Get.to(() => const AppNavigator());
              },
            ),
          ),
        ],
      ),
    );
  }
}
