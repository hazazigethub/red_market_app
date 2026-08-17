import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:red_market/core/routing/route_paths.dart'; // ✅ استيراد المسارات لضمان التوافق

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20), // ✅ أيقونة متوافقة مع البروفايل
            onPressed: () => context.pop(),
          ),
          title: const Text("الشروط والأحكام",
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
              Text("اتفاقية الاستخدام",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo')),
              SizedBox(height: 15),
              Text(
                "باستخدامك لتطبيق 2030، فإنك توافق على الالتزام بالشروط التالية:\n\n"
                "1. شروط الحساب: يجب تقديم معلومات دقيقة عند التسجيل.\n"
                "2. السلوك المقبول: يمنع استخدام التطبيق في أي أغراض غير قانونية.\n"
                "3. المسؤولية: التطبيق غير مسؤول عن سوء استخدام الخدمة من قبل الأطراف الخارجية.\n"
                "4. التعديلات: نحتفظ بالحق في تعديل هذه الشروط في أي وقت مع إخطار المستخدمين.",
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
