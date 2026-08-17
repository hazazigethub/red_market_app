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
      "q": "كيف يمكنني تتبع طلبي؟",
      "a":
          "يمكنك تتبع حالة الطلب من خلال قسم 'الطلبات' في القائمة السفلية، حيث تظهر حالة الطلب فور تحديثها من قبل المتجر."
    },
    {
      "q": "هل يمكنني إلغاء الحجز بعد تأكيده؟",
      "a":
          "نعم، يمكنك إلغاء الحجز قبل الموعد بـ 24 ساعة على الأقل من خلال تفاصيل الحجز، أو عبر التواصل المباشر مع المتجر."
    },
    {
      "q": "ما هي وسائل الدفع المتاحة؟",
      "a":
          "نقبل حالياً الدفع النقدي عند الاستلام، والبطاقات الائتمانية، ومدى، بالإضافة إلى Apple Pay."
    },
    {
      "q": "كيف أغير موقع التسليم؟",
      "a": "يمكنك تغيير الموقع من خلال الإعدادات أو عند تأكيد الطلب قبل إتمامه."
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
