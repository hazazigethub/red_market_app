import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:red_market/core/routing/route_paths.dart'; // ✅ استيراد المسارات

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final List<Map<String, String>> _faqs = [
    {
      "q": "ما هو رد ماركت؟",
      "a":
          "منصة تجمع لك منتجات وعروض متاجر متعددة في مكان واحد، لتتصفحها وتقارن بينها بسهولة، ثم تنتقل مباشرة إلى صفحة المنتج في متجره لإتمام الشراء."
    },
    {
      "q": "كيف أشتري منتجاً؟",
      "a":
          "اختر المنتج الذي يعجبك، ثم اضغط على زر الانتقال للمتجر. سيفتح لك موقع المتجر مباشرة لتكمل عملية الشراء لديه."
    },
    {
      "q": "هل يتم الشراء والدفع داخل رد ماركت؟",
      "a":
          "لا. رد ماركت منصة عرض وإحالة فقط. الشراء والدفع والشحن والإرجاع تتم لدى المتجر نفسه ووفق سياساته."
    },
    {
      "q": "هل الأسعار والمنتجات محدّثة؟",
      "a":
          "يقوم كل تاجر بإضافة منتجاته وتحديث أسعارها بنفسه. ننصح دائماً بالتأكد من السعر والتوفر في صفحة المنتج داخل المتجر قبل الشراء."
    },
    {
      "q": "كيف أحفظ منتجاً للرجوع إليه لاحقاً؟",
      "a":
          "سجّل الدخول ثم أضف المنتج إلى المفضلة، وستجده في أي وقت داخل حسابك."
    },
    {
      "q": "لدي متجر، كيف أعرض منتجاتي؟",
      "a":
          "يمكنك تسجيل متجرك عبر موقع رد ماركت وإدارة منتجاتك من لوحة التاجر. تواصل معنا عبر خدمة العملاء لمعرفة التفاصيل."
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color brandGreen = Color(0xFF4CAF50);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
          title: const Text("الأسئلة الشائعة",
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.quiz_outlined, size: 80, color: brandGreen),
            const SizedBox(height: 20),
            Text(
              "كيف يمكننا مساعدتك اليوم؟",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 30),
            ..._faqs.map((faq) => Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                  ),
                  child: ExpansionTile(
                    iconColor: brandGreen,
                    collapsedIconColor: Colors.grey,
                    shape: const Border(),
                    title: Text(faq['q']!,
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(faq['a']!,
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.grey,
                                fontSize: 13,
                                height: 1.6)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
