import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:red_market/core/routing/route_paths.dart';
import 'package:red_market/app/app.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Future<Map<String, int>> _fetchLiveStats() async {
    final supabase = Supabase.instance.client;
    try {
      final productsRes =
          await supabase.from('products').select('id').count(CountOption.exact);
      final usersRes = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'user')
          .count(CountOption.exact);
      final merchantsRes = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'merchant')
          .count(CountOption.exact);
      final visitsRes = await supabase
          .from('analytics_visits')
          .select('id')
          .count(CountOption.exact);
      return {
        'products': productsRes.count,
        'users': usersRes.count,
        'merchants': merchantsRes.count,
        'visits': visitsRes.count,
      };
    } catch (e) {
      debugPrint("Error fetching stats: $e");
      return {'products': 0, 'users': 0, 'merchants': 0, 'visits': 0};
    }
  }

  Future<int> _fetchNewReportsCount() async {
    final supabase = Supabase.instance.client;
    try {
      final res = await supabase
          .from('reports')
          .select('id')
          .eq('status', 'pending')
          .count(CountOption.exact);
      return res.count;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color brandRed = Color(0xFFC21815);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: brandRed,
          elevation: 0,
          title: const Text(
            "لوحة الإدارة",
            style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            // ✅ زر الوضع الليلي
            IconButton(
              onPressed: () {
                final current = ref.read(appThemeModeProvider);
                ref.read(appThemeModeProvider.notifier).state =
                    current == ThemeMode.dark
                        ? ThemeMode.light
                        : ThemeMode.dark;
              },
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () => context.go(RoutePaths.home),
              icon: const Icon(Icons.home_outlined,
                  color: Colors.white, size: 26),
              tooltip: "العودة للرئيسية",
            ),
          ],
        ),
        body: FutureBuilder<Map<String, int>>(
          future: _fetchLiveStats(),
          builder: (context, snapshot) {
            final stats = snapshot.data;
            final bool isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "احصائيات عامة",
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 15),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _buildStatCard(
                          "عدد الزيارات",
                          isLoading ? "..." : "${stats?['visits']}",
                          Icons.visibility,
                          Colors.blue,
                          isDark,
                          () => context.push('/admin-analytics-visits')),
                      _buildStatCard(
                          "عدد المنتجات",
                          isLoading ? "..." : "${stats?['products']}",
                          Icons.inventory_2,
                          Colors.orange,
                          isDark,
                          () => context.push('/admin-analytics-products')),
                      _buildStatCard(
                          "احصائيات المنتجات لكل تصنيف",
                          "تصنيفات المنتجات",
                          Icons.pie_chart,
                          Colors.teal,
                          isDark,
                          () => context
                              .push('/admin-analytics-product-categories')),
                      _buildStatCard(
                          "احصائيات المتاجر لكل تصنيف",
                          "تصنيفات المتاجر",
                          Icons.category,
                          Colors.indigo,
                          isDark,
                          () => context
                              .push('/admin-analytics-merchant-categories')),
                      _buildStatCard(
                          "عدد العملاء",
                          isLoading ? "..." : "${stats?['users']}",
                          Icons.people,
                          Colors.green,
                          isDark,
                          () => context.push('/admin-analytics-users')),
                      _buildStatCard(
                          "عدد التجار",
                          isLoading ? "..." : "${stats?['merchants']}",
                          Icons.storefront,
                          Colors.purple,
                          isDark,
                          () => context.push('/admin-analytics-merchants')),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "أدوات الإدارة",
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 15),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 1.3,
                    children: [
                      _buildAdminMenu(context, "إدارة العملاء",
                          Icons.person_search_outlined, brandRed, isDark, () {
                        context.push(RoutePaths.adminUsers);
                      }),
                      _buildAdminMenu(context, "إدارة التجار",
                          Icons.manage_accounts_outlined, brandRed, isDark, () {
                        context.push(RoutePaths.adminMerchants);
                      }),
                      _buildAdminMenu(context, "إدارة التصنيفات",
                          Icons.category_outlined, brandRed, isDark, () {
                        context.push(RoutePaths.adminCategories);
                      }),
                      _buildAdminMenu(context, "إدارة المنتجات",
                          Icons.inventory_2_outlined, brandRed, isDark, () {
                        context.push(RoutePaths.adminProductsControl);
                      }),
                      _buildAdminMenu(context, "إدارة البنرات",
                          Icons.ad_units_outlined, brandRed, isDark, () {
                        context.push(RoutePaths.adminBanners);
                      }),
                      _buildAdminMenu(context, "إدارة الباقات",
                          Icons.card_membership_outlined, brandRed, isDark, () {
                        context.push(RoutePaths.adminCreateSubscription);
                      }),
                      FutureBuilder<int>(
                        future: _fetchNewReportsCount(),
                        builder: (context, reportsSnapshot) {
                          final count = reportsSnapshot.data ?? 0;
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildAdminMenu(
                                  context,
                                  "نظام البلاغات",
                                  Icons.report_problem_outlined,
                                  brandRed,
                                  isDark, () {
                                context.push('/admin-reports');
                              }),
                              if (count > 0)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      count > 99 ? '+99' : '$count',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo'),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      _buildAdminMenu(context, "إعدادات النظام",
                          Icons.settings_outlined, brandRed, isDark, () {
                        context.push(RoutePaths.adminSettings);
                      }),
                      _buildAdminMenu(context, "ترويج عام",
                          Icons.campaign_rounded, brandRed, isDark, () {
                        context.push('/admin-announcements');
                      }),
                      _buildAdminMenu(context, "إدارة الإشعارات",
                          Icons.campaign_outlined, brandRed, isDark, () {
                        context.push(RoutePaths.adminNotifications);
                      }),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "سياسات التطبيق",
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 15),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 1.3,
                    children: [
                      _buildAdminMenu(context, "شروط العميل",
                          Icons.gavel_rounded, brandRed, isDark, () {
                        context.push(RoutePaths.customerTerms);
                      }),
                      _buildAdminMenu(
                          context,
                          "شروط التاجر",
                          Icons.assignment_turned_in_outlined,
                          brandRed,
                          isDark, () {
                        context.push(RoutePaths.merchantTerms);
                      }),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      bool isDark, VoidCallback onTap) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFC21815).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                radius: 18,
                child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenu(BuildContext context, String title, IconData icon,
      Color color, bool isDark, VoidCallback onTap) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFC21815).withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
