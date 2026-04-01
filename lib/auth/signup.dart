import 'package:bonless61/core/theme/app_colors.dart';
import 'package:bonless61/wigets/widgetexport.dart';
import 'package:flutter/material.dart';
import 'package:date_time_picker/date_time_picker.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool isPasswordHidden = true;
  bool agree = false;

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
          buildInputField(
            label: 'PHONE NUMBER',
            hint: 'PHONE NUMBER',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone,
            inputHeight: fieldHeight,
            labelFontSize: labelFontSize,
            labelSpacing: labelSpacing,
            borderRadius: fieldRadius,
          ),
          SizedBox(height: fieldGap),
          buildInputField(
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
            text: 'CREATE ACCOUNT',
            height: compact ? 48 : 60,
            fontSize: compact ? 14 : 16,
            borderRadius: compact ? 22 : 28,
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