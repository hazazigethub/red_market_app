import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ إضافة ريفربود
import 'package:go_router/go_router.dart';
import 'package:red_market/core/routing/route_paths.dart';
import 'package:red_market/main.dart'; // ✅ للوصول لمزود نوع التطبيق

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  // الخطوة النهائية: رسالة التحذير وإدخال كلمة CONFIRM
  void _showFinalWarningDialog(BuildContext context) {
    final TextEditingController confirmController = TextEditingController();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.report_problem_rounded, color: Colors.red),
                SizedBox(width: 10),
                Text("تحذير نهائي!",
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "سيتم حذف كافة بيانات المتجر، الطلبات، السجلات المالية، والمنتجات بشكل نهائي ولا يمكن استعادتها.",
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "اكتب كلمة CONFIRM للتأكيد:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmController,
                  autofocus: true,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: "CONFIRM",
                    hintStyle: TextStyle(
                        color: isDark ? Colors.white24 : Colors.grey,
                        fontSize: 13),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 12),
                  ),
                  onChanged: (val) => setDialogState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: Text("تراجع",
                    style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey,
                        fontFamily: 'Cairo')),
              ),
              ElevatedButton(
                onPressed: confirmController.text == "CONFIRM"
                    ? () {
                        // 1. إعادة حالة التطبيق لوضع المصادقة (Auth)
                        ref.read(appTypeProvider.notifier).state = AppType.auth;
                        // 2. توجيه المستخدم لصفحة الدخول
                        context.go(RoutePaths.login);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.red.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("تأكيد الحذف",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text("حذف الحساب",
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                fontSize: 18)),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_accounts_outlined,
                  size: 120, color: Colors.redAccent),
              const SizedBox(height: 30),
              Text(
                "نأسف لقرارك بالمغادرة",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "حذف حساب التاجر يعني فقدان علامتك التجارية في التطبيق، ومسح قائمة المنتجات، وفقدان الوصول إلى سجلاتك المالية والطلبات السابقة.",
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    fontFamily: 'Cairo',
                    height: 1.6),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => _showFinalWarningDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("استمرار في إجراءات الحذف",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo')),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text("لا أرغب بالحذف، العودة للإعدادات",
                    style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
