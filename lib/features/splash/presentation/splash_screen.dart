import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:red_market/core/routing/route_paths.dart';
import 'package:red_market/app/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleInitialFlow();
  }

  Future<void> _handleInitialFlow() async {
    // 1. انتظار بسيط لضمان استقرار استعادة الجلسة من الذاكرة المحلية
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    // حالة (أ): لا توجد جلسة مخزنة - نترك الروتر يوجه للـ Login تلقائياً
    if (session == null) {
      debugPrint("Auth Check: No Session Found");
      if (mounted) {
        context.go(RoutePaths.login); // ✅ يجب إضافة هذا السطر للانتقال فعلياً
      }
      return;
    }

    try {
      // حالة (ب): جلب البيانات لتحديث الحالة فقط
      final userData = await supabase
          .from('profiles')
          .select('is_banned, role')
          .eq('id', session.user.id)
          .maybeSingle();

      debugPrint("Auth Check Result: $userData");

      if (userData != null && userData['is_banned'] == true) {
        debugPrint("Auth Check: User is Banned");
        await supabase.auth.signOut();
        // بعد الخروج، سيوجه الروتر تلقائياً للـ Login
      } else {
        // ✅ المهمة الوحيدة: تحديث الـ Provider ليعلم الروتر أين يذهب بالمستخدم
        if (userData != null && userData['role'] != null) {
          ref.read(userRoleProvider.notifier).state = userData['role'];
          debugPrint("User Role Updated to: ${userData['role']}");
        }
        debugPrint("Auth Check: User is Clear");
      }
    } catch (e) {
      debugPrint("Auth Check Error: $e");
      // في حال الخطأ، الروتر سيتعامل مع الحالة الحالية للجلسة
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xFFC21815);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 220,
              height: 220,
              errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.storefront_rounded,
                  size: 100,
                  color: brandColor),
            ),
            const SizedBox(height: 30),
            const Text(
              "رد ماركت",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: brandColor,
                letterSpacing: 1.5,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(brandColor),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
