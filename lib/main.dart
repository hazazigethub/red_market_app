import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:red_market/app/app.dart';
import 'package:red_market/core/routing/app_router.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:red_market/app/notifications_observer.dart';
import 'package:flutter/services.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

enum AppType { customer, merchant, auth }

final appTypeProvider = StateProvider<AppType>((ref) => AppType.auth);
final merchantBalanceProvider = StateProvider<double>((ref) => 0.0);

final merchantProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  try {
    final response =
        await supabase.from('products').select().eq('merchant_id', user.id);
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

Future<void> logVisit() async {
  if (isAppVisitLogged) return;
  try {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    String platformName = 'unknown';
    if (kIsWeb) {
      platformName = 'web';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      platformName = 'android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      platformName = 'ios';
    }
    await supabase.from('analytics_visits').insert({
      'page_name': 'app_launch',
      'platform': platformName,
      'user_id': user?.id,
      'visited_at': DateTime.now().toIso8601String(),
    });
    isAppVisitLogged = true;
    debugPrint("🚀 Analytics: New Visit Logged Successfully");
  } catch (e) {
    debugPrint("Analytics Error: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await initializeDateFormatting('ar', null);
  tz.initializeTimeZones();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await Supabase.initialize(
    url: 'https://ycuzwfsaxnfbdskerjfw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljdXp3ZnNheG5mYmRza2VyamZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1Mjc2ODAsImV4cCI6MjA4NzEwMzY4MH0.Eh88kUtJGYaRyeYCunpKVteVARIP1i2V1mJCQYLgDtY',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );

  String? savedRole;
  try {
    final prefs = await SharedPreferences.getInstance();
    savedRole = prefs.getString('user_role');
    debugPrint("✅ الدور المحفوظ: $savedRole");
  } catch (e) {
    debugPrint("خطأ في قراءة SharedPreferences: $e");
  }

  runApp(
    ProviderScope(
      overrides: [
        if (savedRole != null)
          userRoleProvider.overrideWith((ref) => savedRole),
      ],
      child: const MyApp(),
    ),
  );
}

bool isAppVisitLogged = false;

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appType = ref.watch(appTypeProvider);
    ref.watch(currentUserProfileProvider);

    // ✅ provider واحد للكل
    final activeThemeMode = ref.watch(appThemeModeProvider);

    return OverlaySupport.global(
        child: MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      themeMode: activeThemeMode,
      builder: (context, child) => child!,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Cairo',
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Cairo',
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF4CAF50),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Color(0xFF1E1E1E),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF1E1E1E),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1E1E1E),
        ),
      ),
    ));
  }
}

class TermsGuard extends ConsumerStatefulWidget {
  final Widget child;
  const TermsGuard({super.key, required this.child});

  @override
  ConsumerState<TermsGuard> createState() => _TermsGuardState();
}

class _TermsGuardState extends ConsumerState<TermsGuard> {
  bool _showOverlay = false;
  int _latestVersion = 0;
  String _termsContent = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTermsVersion());
  }

  Future<void> _checkTermsVersion() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final appType = ref.read(appTypeProvider);
    String targetType = (appType == AppType.merchant) ? 'merchant' : 'customer';
    try {
      final userData = await Supabase.instance.client
          .from('profiles')
          .select('accepted_terms_version')
          .eq('id', user.id)
          .single();
      final termsVersionData = await Supabase.instance.client
          .from('terms_content')
          .select('version')
          .eq('type', targetType)
          .single();
      int userVersion = userData['accepted_terms_version'] ?? 0;
      _latestVersion = termsVersionData['version'] ?? 0;
      if (_latestVersion > userVersion) {
        final termsFullData = await Supabase.instance.client
            .from('terms_content')
            .select('content')
            .eq('type', targetType)
            .eq('version', _latestVersion)
            .single();
        _termsContent = termsFullData['content'] ?? "";
        if (mounted) setState(() => _showOverlay = true);
      }
    } catch (e) {
      debugPrint("Terms Check Error: $e");
    }
  }

  Future<void> _acceptTerms() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('profiles').update(
          {'accepted_terms_version': _latestVersion}).eq('id', user!.id);
      if (mounted)
        setState(() {
          _showOverlay = false;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showOverlay,
      child: Stack(
        children: [
          widget.child,
          if (_showOverlay)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  color: Colors.black.withOpacity(0.9),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 25),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.security_update_warning_rounded,
                              size: 60, color: Colors.orange),
                          const SizedBox(height: 16),
                          const Text("تحديث الشروط والأحكام",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  fontFamily: 'Cairo')),
                          const SizedBox(height: 12),
                          const Text(
                              "يجب الموافقة على التحديثات الجديدة للمتابعة:",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                  fontFamily: 'Cairo')),
                          const SizedBox(height: 16),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[200]!)),
                              child: SingleChildScrollView(
                                child: Text(_termsContent,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        fontFamily: 'Cairo')),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10))),
                                    onPressed: _acceptTerms,
                                    child: const Text(
                                        "أوافق على الشروط الجديدة",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Cairo')),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
