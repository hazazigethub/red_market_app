import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:red_market/core/routing/route_paths.dart'; // ✅ استيراد المسارات لضمان التوافق

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20), // ✅ تحديث الأيقونة لتناسب التصميم
            onPressed: () => context.pop(),
          ),
          title: const Text("سياسة الخصوصية",
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("سياسة الخصوصية وتطبيق 2030",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo')),
              SizedBox(height: 15),
              Text(
                "نحن في تطبيق 2030 نولي أهمية كبرى لخصوصية بياناتك. توضح هذه السياسة كيفية جمع واستخدام وحماية المعلومات الشخصية التي تقدمها لنا.\n\n"
                "1. جمع المعلومات: نقوم بجمع المعلومات اللازمة لتقديم خدمات التوصيل والحجز.\n"
                "2. استخدام البيانات: تُستخدم البيانات لتحسين تجربتك وتوفير الدعم الفني.\n"
                "3. حماية المعلومات: نطبق معايير أمان عالية لضمان عدم وصول أطراف غير مصرح لها لبياناتك.",
                style: TextStyle(
                    fontSize: 14,
                    height: 1.8,
                    fontFamily: 'Cairo',
                    color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
