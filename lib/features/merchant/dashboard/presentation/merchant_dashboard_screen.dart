import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:RedOcean/core/routing/route_paths.dart';
import 'package:RedOcean/app/app.dart';
import 'package:RedOcean/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ✅ الموديلات والصفحات
import 'package:RedOcean/core/models/merchant_model.dart';
import 'package:RedOcean/features/customer/home/presentation/pages/store_details_page.dart';

// ✅ صفحات الداشبورد
import 'package:RedOcean/features/merchant/dashboard/presentation/pages/merchant_reports_page.dart';
import 'package:RedOcean/features/merchant/dashboard/presentation/pages/products_page.dart';
import 'package:RedOcean/features/merchant/dashboard/presentation/pages/store_settings_page.dart';
import 'package:RedOcean/features/merchant/dashboard/presentation/pages/manage_reels_page.dart';
import 'package:RedOcean/features/merchant/dashboard/presentation/pages/merchant_subscriptions_page.dart';
import 'package:RedOcean/features/merchant/dashboard/presentation/usefullinks/useful_links_page.dart';

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class MerchantDashboardScreen extends ConsumerStatefulWidget {
  final String? merchantId;
  const MerchantDashboardScreen({super.key, this.merchantId});

  @override
  ConsumerState<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState
    extends ConsumerState<MerchantDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final supabase = Supabase.instance.client;
  static const Color brandColor = Color(0xFFC21815);

  // ✅ مضاف: متغيرات صلاحيات الباقة
  bool _hasBasicReports = false;
  bool _hasDetailedReports = false;
  bool _isSubscriptionActive = false;
  bool _hasPlan = false;
  bool _subscriptionBannerShown = false;

  String? _planName;
  DateTime? _subscriptionStartDate;
  DateTime? _subscriptionEndDate;

  Stream<Map<String, dynamic>?> _getMyStoreData() {
    final userId = widget.merchantId ?? supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value(null);

    return supabase
        .from('merchants')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
          if (data.isEmpty) return null;
          // تحويل آمن للبيانات لمنع خطأ type 'String' is not a subtype of type 'int'
          return Map<String, dynamic>.from(data.first);
        });
  }

  Future<void> _checkSubscriptionStatus() async {
    if (_subscriptionBannerShown) return;
    try {
      final userId = widget.merchantId ?? supabase.auth.currentUser?.id;
      if (userId == null) return;

      // ✅ إذا كان الأدمن — تخطى فحص الاشتراك
      if (widget.merchantId != null &&
          widget.merchantId != supabase.auth.currentUser?.id) {
        setState(() => _subscriptionBannerShown = true);
        return;
      }

      final profile = await supabase
          .from('profiles')
          .select('plan_id, is_subscription_active')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null || !mounted) return;

      final bool isActive = profile['is_subscription_active'] ?? false;
      final bool hasPlan = profile['plan_id'] != null;

      setState(() {
        _isSubscriptionActive = isActive;
        _hasPlan = hasPlan;
        _subscriptionBannerShown = true;
      });

      if (!isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showSubscriptionDialog(hasPlan);
        });
      }
    } catch (e) {
      debugPrint("خطأ في فحص الاشتراك: $e");
    }
  }

  void _showSubscriptionDialog(bool hasPlan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(
            hasPlan ? Icons.refresh_rounded : Icons.card_membership_rounded,
            color: brandColor,
            size: 48,
          ),
          title: Text(
            hasPlan ? "انتهى اشتراكك" : "لم تفعّل باقتك بعد",
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Text(
            hasPlan
                ? "انتهت صلاحية اشتراكك — منتجاتك وريلزك لن تظهر للعملاء حتى تجدد."
                : "منتجاتك وريلزك لن تظهر للعملاء حتى تفعّل إحدى الباقات.",
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("لاحقاً",
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MerchantSubscriptionsPage()),
                );
              },
              child: Text(
                hasPlan ? "تجديد الاشتراك" : "تفعيل الباقة",
                style:
                    const TextStyle(fontFamily: 'Cairo', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ مضاف: جلب صلاحيات التقارير من باقة التاجر
  Future<void> _fetchPlanFeatures() async {
    try {
      final userId = widget.merchantId ?? supabase.auth.currentUser?.id;
      if (userId == null) return;

      // ✅ إذا كان الأدمن يشاهد داشبورد التاجر — أعطه صلاحيات كاملة
      final isAdminViewing = widget.merchantId != null &&
          widget.merchantId != supabase.auth.currentUser?.id;
      if (isAdminViewing) {
        // جلب بيانات الباقة للعرض فقط
        final profile = await supabase
            .from('profiles')
            .select('plan_id, subscription_start_date, subscription_end_date')
            .eq('id', userId)
            .maybeSingle();

        if (profile != null && profile['plan_id'] != null) {
          final plan = await supabase
              .from('subscription_plans')
              .select('name')
              .eq('id', profile['plan_id'])
              .maybeSingle();
          if (mounted) {
            setState(() {
              _planName = plan?['name']?.toString();
              _hasBasicReports = true;
              _hasDetailedReports = true;
              _isSubscriptionActive = true;
              _hasPlan = true;
              _subscriptionStartDate =
                  profile['subscription_start_date'] != null
                      ? DateTime.parse(profile['subscription_start_date'])
                      : null;
              _subscriptionEndDate = profile['subscription_end_date'] != null
                  ? DateTime.parse(profile['subscription_end_date'])
                  : null;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _hasBasicReports = true;
              _hasDetailedReports = true;
              _isSubscriptionActive = true;
              _hasPlan = true;
            });
          }
        }
        return; // ✅ توقف هنا — لا تكمل باقي الدالة
      }

      final profile = await supabase
          .from('profiles')
          .select('plan_id')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null || profile['plan_id'] == null) return;

      final plan = await supabase
          .from('subscription_plans')
          .select('has_basic_reports, has_detailed_reports, name')
          .eq('id', profile['plan_id'])
          .maybeSingle();

      if (plan != null && mounted) {
        setState(() {
          _hasBasicReports = plan['has_basic_reports'] ?? false;
          _hasDetailedReports = plan['has_detailed_reports'] ?? false;
          _planName = plan['name']?.toString();
        });
      }

      // ✅ جلب تواريخ الاشتراك
      final profileDates = await supabase
          .from('profiles')
          .select('subscription_start_date, subscription_end_date')
          .eq('id', userId)
          .maybeSingle();

      if (profileDates != null && mounted) {
        setState(() {
          _subscriptionStartDate =
              profileDates['subscription_start_date'] != null
                  ? DateTime.parse(profileDates['subscription_start_date'])
                  : null;
          _subscriptionEndDate = profileDates['subscription_end_date'] != null
              ? DateTime.parse(profileDates['subscription_end_date'])
              : null;
        });
      }
    } catch (e) {
      debugPrint("خطأ في جلب صلاحيات الباقة: $e");
    }
  }

  // ✅ دالة التحقق من اكتمال البيانات الأساسية (تم تعديلها لمنع الطرد التلقائي حالياً)
  void _checkStoreCompletion(Map<String, dynamic>? data) {
    if (data == null) return;

    final String? logo = data['logo_url'];
    final String? url = data['store_url'];

    // تم تعطيل التوجيه التلقائي مؤقتاً للسماح لك بدخول الداشبورد حتى لو البيانات ناقصة
    if ((logo == null || logo.isEmpty) || (url == null || url.isEmpty)) {
      debugPrint(
          "ℹ️ تنبيه: بيانات المتجر غير مكتملة، يرجى تحديثها من الإعدادات.");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPlanFeatures();
    _checkSubscriptionStatus();
    Future.microtask(() {
      if (ref.read(appTypeProvider) != AppType.merchant) {
        ref.read(appTypeProvider.notifier).state = AppType.merchant;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        body: StreamBuilder<Map<String, dynamic>?>(
          stream: _getMyStoreData(),
          builder: (context, snapshot) {
            // تنفيذ فحص اكتمال البيانات بمجرد وصول الداتا
            if (snapshot.hasData) {
              _checkStoreCompletion(snapshot.data);
            }

            return Column(
              children: [
                _buildTopHeader(isDark, snapshot.data),
                Expanded(
                  child: RefreshIndicator(
                    color: brandColor,
                    onRefresh: () async {
                      await _fetchPlanFeatures();
                    },
                    child: _buildGridMenu(isDark),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader(bool isDark, Map<String, dynamic>? storeData) {
    final storeName = storeData?['store_name'] ?? "جاري التحميل...";
    final logoUrl = storeData?['logo_url'];

    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          bottom: 12),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ]),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: (logoUrl != null && logoUrl.toString().isNotEmpty)
              ? NetworkImage(logoUrl)
              : null,
          child: (logoUrl == null || logoUrl.toString().isEmpty)
              ? const Icon(Icons.storefront_rounded,
                  color: brandColor, size: 22)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("لوحة تحكم التاجر",
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
              Row(
                children: [
                  Text(storeName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo')),
                  if (_planName != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: brandColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: brandColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        _planName!,
                        style: const TextStyle(
                            fontSize: 10,
                            color: brandColor,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            final prefs = SharedPreferences.getInstance();
            prefs.then((p) => p.setString('user_role', 'merchant'));
            context.go(RoutePaths.home);
          },
          child: const Icon(Icons.home_outlined, color: brandColor, size: 22),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            final current = ref.read(appThemeModeProvider);
            ref.read(appThemeModeProvider.notifier).state =
                current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ref.watch(appThemeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: brandColor,
              size: 22,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildGridMenu(bool isDark) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'إدارة المنتجات',
        'icon': Icons.inventory_2_rounded,
        'page': const ProductsPage(),
        'color': Colors.blue,
        'locked': false, // ✅ مضاف
      },
      {
        'title': 'إدارة الريلز',
        'icon': Icons.play_circle_fill_rounded,
        'page': const ManageReelsPage(),
        'color': Colors.redAccent,
        'locked': false, // ✅ مضاف
      },
      {
        'title': 'الاشتراكات',
        'icon': Icons.card_membership_rounded,
        'page': const MerchantSubscriptionsPage(),
        'color': Colors.teal,
        'locked': false, // ✅ مضاف
      },
      {
        'title': 'التقارير',
        'icon': Icons.analytics_rounded,
        'page': const MerchantReportsPage(),
        'color': Colors.orange
      },
      {
        'title': 'إعدادات المتجر',
        'icon': Icons.settings_suggest_rounded,
        'page': const StoreSettingsPage(),
        'color': brandColor,
        'locked': false, // ✅ مضاف
      },
      {
        'title': 'زيارة المتجر',
        'icon': Icons.remove_red_eye_rounded,
        'page': null,
        'color': Colors.cyan,
        'locked': false, // ✅ مضاف
      },
      {
        'title': 'روابط تهمك',
        'icon': Icons.link_rounded,
        'page': const UsefulLinksPage(),
        'color': Colors.purple,
        'locked': false, // ✅ مضاف
      },
      {
        'title': 'تسجيل الخروج',
        'icon': Icons.logout_rounded,
        'page': null,
        'color': Colors.grey,
        'locked': false, // ✅ مضاف
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final bool isLocked = item['locked'] as bool? ?? false;
        return _buildMenuCard(
          title: item['title'],
          icon: item['icon'],
          color: item['color'],
          isDark: isDark,
          isLocked: isLocked, // ✅ مضاف
          onTap: () async {
            // ✅ مضاف: إذا كان مقفلاً أظهر رسالة ترقية
            if (isLocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "هذه الميزة غير متاحة في باقتك الحالية. رقّ باقتك للوصول إليها.",
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            if (item['title'] == 'تسجيل الخروج') {
              await supabase.auth.signOut();
              if (mounted) context.go(RoutePaths.login);
            } else if (item['title'] == 'زيارة المتجر') {
              try {
                final String currentUserId = supabase.auth.currentUser!.id;
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StoreDetailsPage(merchantId: currentUserId),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("خطأ: $e")));
              }
            } else if (item['title'] == 'إدارة المنتجات') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ProductsPage(merchantId: widget.merchantId)));
            } else if (item['title'] == 'إدارة الريلز') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ManageReelsPage(merchantId: widget.merchantId)));
            } else if (item['title'] == 'التقارير') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          MerchantReportsPage(merchantId: widget.merchantId)));
            } else if (item['title'] == 'الاشتراكات') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MerchantSubscriptionsPage()));
            } else if (item['title'] == 'إعدادات المتجر') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          StoreSettingsPage(merchantId: widget.merchantId)));
            } else if (item['title'] == 'روابط تهمك') {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UsefulLinksPage()));
            }
          },
        );
      },
    );
  }

  Widget _buildMenuCard(
      {required String title,
      required IconData icon,
      required Color color,
      required bool isDark,
      required bool isLocked, // ✅ مضاف
      required VoidCallback onTap}) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: isLocked
                          ? Colors.grey.withOpacity(0.1) // ✅ مضاف
                          : color.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Icon(icon,
                      color: isLocked ? Colors.grey : color, // ✅ مضاف
                      size: 32),
                ),
                // ✅ مضاف: أيقونة القفل
                if (isLocked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded,
                          color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isLocked ? Colors.grey : null)), // ✅ مضاف
          ],
        ),
      ),
    );
  }
}
