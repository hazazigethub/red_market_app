import 'package:flutter/material.dart';
import 'package:red_market/core/config/app_colors.dart';

class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chat_bubble_outline,
            size: 150, color: AppColors.primary.withOpacity(0.8)),
        const SizedBox(height: 40),
        const Text("سهولة التواصل",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text("تواصل مع المتاجر وتابع طلباتك في مكان واحد.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      ],
    );
  }
}
