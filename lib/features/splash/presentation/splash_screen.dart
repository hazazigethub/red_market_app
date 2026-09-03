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
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    // حالة (أ): لا توجد جلسة مخزنة - نترك الروتر يوجه للـ Login تلقائياً
    if (session == null) {
      debugPrint("Auth Check: No Session Found");
      ref.read(splashDoneProvider.notifier).state = true;
      if (mounted) {
        context.go(RoutePaths.login);
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
      } else {
        if (userData != null && userData['role'] != null) {
          ref.read(userRoleProvider.notifier).state = userData['role'];
          debugPrint("User Role Updated to: ${userData['role']}");
        }
        debugPrint("Auth Check: User is Clear");
      }
    } catch (e) {
      debugPrint("Auth Check Error: $e");
    }

    // رفع العلامة يسمح للراوتر بالانتقال
    if (!mounted) return;
    ref.read(splashDoneProvider.notifier).state = true;

    final target = Supabase.instance.client.auth.currentSession == null
        ? RoutePaths.login
        : RoutePaths.home;
    if (mounted) context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xFFC21815);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // الشعار المربّع
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Image.asset(
                    'assets/images/applogo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.storefront_rounded,
                        size: 90,
                        color: brandColor),
                  ),
                ),

                const SizedBox(height: 24),

                // الشعار العريض
                SizedBox(
                  width: 230,
                  height: 80,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      'RED MARKET',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: brandColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(brandColor),
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
