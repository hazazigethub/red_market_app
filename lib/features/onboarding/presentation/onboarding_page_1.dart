import 'package:flutter/material.dart';
import 'package:red_market/core/config/app_colors.dart';

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.storefront,
            size: 150, color: AppColors.primary.withOpacity(0.8)),
        const SizedBox(height: 40),
        const Text("اكتشف المتاجر القريبة",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text("تصفح أفضل المتاجر والمطاعم والخدمات الموجودة في منطقتك.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      ],
    );
  }
}
