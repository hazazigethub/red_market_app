import 'dart:async';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:red_market/core/routing/route_paths.dart';
import 'package:red_market/app/app.dart' hide userRoleProvider;
import 'package:red_market/app/app_providers.dart';

import 'package:red_market/features/customer/home/presentation/pages/home_screen.dart'
    as customer;
import 'package:red_market/features/merchant/dashboard/presentation/merchant_dashboard_screen.dart'
    as merchant;

import '../../features/merchant/dashboard/presentation/pages/payment_selection_screen.dart';
import 'package:red_market/features/splash/presentation/splash_screen.dart';
import 'package:red_market/core/models/merchant_model.dart';
import 'package:red_market/core/models/product_model.dart';

import 'package:red_market/features/auth/presentation/login_screen.dart';
import 'package:red_market/features/auth/presentation/register_screen.dart';
import 'package:red_market/features/auth/presentation/merchant_register_screen.dart';
import 'package:red_market/features/auth/presentation/otp_screen.dart';
import 'package:red_market/core/utils/payment_args.dart';

import 'package:red_market/features/customer/home/presentation/pages/interests_selection_screen.dart';
import 'package:red_market/features/customer/home/presentation/pages/store_details_page.dart';
import 'package:red_market/features/customer/home/presentation/pages/notifications_page.dart';
import 'package:red_market/features/customer/home/presentation/pages/personal_information_page.dart';
import 'package:red_market/features/customer/home/presentation/pages/customer_service_page.dart';
import 'package:red_market/features/customer/home/presentation/pages/product_details_page.dart';

import 'package:red_market/features/merchant/dashboard/presentation/pages/store_settings_page.dart';
import 'package:red_market/features/customer/home/presentation/pages/faq_page.dart';
import 'package:red_market/features/customer/home/presentation/pages/privacy_policy_page.dart';
import 'package:red_market/features/customer/home/presentation/pages/delete_account_page.dart';
import 'package:red_market/features/customer/home/presentation/pages/sub_categories_screen.dart';
import 'package:red_market/features/customer/home/presentation/pages/customer_interests_page.dart';

import 'package:red_market/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:red_market/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:red_market/features/admin/presentation/screens/admin_products_screen.dart';
import 'package:red_market/features/admin/presentation/screens/admin_banners_screen.dart';
import 'package:red_market/features/admin/presentation/screens/admin_notifications_screen.dart';
import 'package:red_market/features/admin/presentation/screens/admin_categories_screen.dart';
import 'package:red_market/features/admin/presentation/screens/admin_customer_screen.dart';
import 'package:red_market/features/admin/presentation/screens/admin_merchants_screen.dart';
import 'package:red_market/features/admin/presentation/screens/customer_terms_page.dart';
import 'package:red_market/features/admin/presentation/screens/merchant_terms_page.dart';
import 'package:red_market/features/admin/presentation/screens/customer_profile_screen.dart';
import 'package:red_market/features/admin/presentation/screens/admin_create_subscription_screen.dart';

import 'package:red_market/features/admin/presentation/screens/admin_analytics_customer_screen.dart';
import 'package:red_market/features/admin/presentation/screens/admin_analytics_merchants_screen.dart';
import 'package:red_market/features/admin/presentation/screens/admin_analytics_visits_screen.dart';
import 'package:red_market/features/admin/presentation/screens/admin_analytics_products_screen.dart';
import 'package:red_market/features/admin/presentation/screens/admin_analytics_merchant_categories_screen.dart';
import 'package:red_market/features/admin/presentation/screens/admin_analytics_product_categories_screen.dart';
import 'package:red_market/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:red_market/features/admin/presentation/screens/maintenance_screen.dart';
import 'package:red_market/features/admin/presentation/screens/admin_announcements_screen.dart';

// كاش وضع الصيانة: يمنع استعلام قاعدة البيانات عند كل تنقل
bool? _maintenanceCache;
DateTime? _maintenanceCachedAt;
const Duration _maintenanceTtl = Duration(minutes: 1);

Future<bool> _isMaintenanceOn() async {
  final now = DateTime.now();
  if (_maintenanceCache != null &&
      _maintenanceCachedAt != null &&
      now.difference(_maintenanceCachedAt!) < _maintenanceTtl) {
    return _maintenanceCache!;
  }
  try {
    final data = await Supabase.instance.client
        .from('system_settings')
        .select('is_maintenance')
        .eq('id', 1)
        .maybeSingle();
    _maintenanceCache = (data?['is_maintenance'] as bool?) ?? false;
  } catch (_) {
    // فشل الاستعلام لا يوقف التنقل
    _maintenanceCache ??= false;
  }
  _maintenanceCachedAt = now;
  return _maintenanceCache!;
}

// ✅ يجب أن يكون هذا الكلاس قبل routerProvider
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    // استمع لتغييرات Auth
    _authSub = Supabase.instance.client.auth.onAuthStateChange
        .listen((_) => notifyListeners());

    // استمع لتغييرات userRole
    ref.listen<String?>(userRoleProvider, (_, __) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _authSub;

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // ✅ notifier بدل ref.watch لمنع إعادة إنشاء الـ router
  final notifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: !kReleaseMode,
    refreshListenable: notifier,
    redirect: (context, state) async {
      final userRole = ref.read(userRoleProvider);
      final session = Supabase.instance.client.auth.currentSession;
      final bool isLoggedIn = session != null;
      final String loc = state.matchedLocation;

      // شاشة الصيانة نفسها مستثناة دائماً لتفادي حلقة إعادة توجيه
      if (loc == RoutePaths.maintenance) return null;

      // فحص وضع الصيانة (مع كاش) قبل أي شيء آخر
      final bool isMaintenance = await _isMaintenanceOn();
      if (isMaintenance && userRole != 'super_admin') {
        return RoutePaths.maintenance;
      }

      if (!isLoggedIn) {
        final bool isAllowedForGuest = loc == RoutePaths.home ||
            loc == '/' ||
            loc == RoutePaths.login ||
            loc == RoutePaths.register ||
            loc == RoutePaths.merchantRegister ||
            loc == RoutePaths.otp ||
            loc == RoutePaths.splash ||
            loc == RoutePaths.customerTerms ||
            loc == RoutePaths.merchantTerms ||
            loc == RoutePaths.subCategories ||
            loc.contains('/product-details') ||
            loc.contains('/merchant-store/') ||
            loc.startsWith(RoutePaths.storeDetails);

        if (isAllowedForGuest) return null;
        return RoutePaths.login;
      }

      // مستخدم مسجّل بدور غير محمّل بعد: يُسمح بالمسارات العامة فقط
      if (userRole == null) {
        final bool isSensitive = loc.startsWith('/admin') ||
            loc.startsWith('/merchant-dashboard') ||
            loc == RoutePaths.adminDashboard ||
            loc == RoutePaths.merchantHome ||
            loc == RoutePaths.storeSettings;
        return isSensitive ? RoutePaths.home : null;
      }

      if (loc == RoutePaths.splash ||
          loc == RoutePaths.login ||
          loc == RoutePaths.otp) {
        return RoutePaths.home;
      }

      if (loc == RoutePaths.register || loc == RoutePaths.merchantRegister) {
        return null;
      }

      // ✅ حماية مسارات الإدارة
      final bool isAdminPath =
          loc.startsWith('/admin') || loc == RoutePaths.adminDashboard;
      if (isAdminPath && userRole != 'super_admin') return RoutePaths.home;

      // ✅ حماية مسارات التجار (بما فيها إعدادات المتجر)
      final bool isMerchantPath = loc.startsWith('/merchant-dashboard') ||
          loc == RoutePaths.merchantHome ||
          loc == RoutePaths.storeSettings;
      if (isMerchantPath &&
          userRole != 'merchant' &&
          userRole != 'super_admin') {
        return RoutePaths.home;
      }

      return null;
    },
    routes: [
      GoRoute(
          path: RoutePaths.splash,
          builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: RoutePaths.home,
          builder: (context, state) => const customer.HomeScreen()),
      GoRoute(
          path: RoutePaths.login,
          builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: RoutePaths.register,
          builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: RoutePaths.otp,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic> ||
              extra['phoneNumber'] is! String) {
            return const LoginScreen();
          }
          return OtpScreen(
            phoneNumber: extra['phoneNumber'] as String,
            isMerchant: (extra['isMerchant'] as bool?) ?? false,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.merchantRegister,
        builder: (context, state) => const MerchantRegisterScreen(),
      ),
      GoRoute(
          path: RoutePaths.interestsSelection,
          builder: (context, state) => const InterestsSelectionScreen()),
      GoRoute(
          path: RoutePaths.adminDashboard,
          builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(
        path: RoutePaths.subCategories,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SubCategoriesScreen(
            parentId: extra?['parentId'] ?? '',
            categoryName: extra?['categoryName'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/product-details',
        builder: (context, state) {
          final product =
              state.extra is ProductModel ? state.extra as ProductModel : null;
          return ProductDetailsPage(product: product);
        },
      ),
      GoRoute(
        path: '/product-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          final product =
              state.extra is ProductModel ? state.extra as ProductModel : null;
          return ProductDetailsPage(productId: id, product: product);
        },
      ),
      GoRoute(
        path: '/merchant-store/:merchantId',
        builder: (context, state) {
          final mId = state.pathParameters['merchantId'];
          return StoreDetailsPage(merchantId: mId ?? '');
        },
      ),
      GoRoute(
        path: RoutePaths.storeDetails,
        builder: (context, state) {
          if (state.extra is MerchantModel) {
            return StoreDetailsPage(
                merchantId: (state.extra as MerchantModel).id);
          }
          final queryId = state.uri.queryParameters['id'];
          return StoreDetailsPage(merchantId: queryId ?? '');
        },
      ),
      GoRoute(
          path: RoutePaths.interests,
          builder: (context, state) => const CustomerInterestsPage()),
      GoRoute(
          path: RoutePaths.merchantHome,
          builder: (context, state) =>
              const merchant.MerchantDashboardScreen()),
      GoRoute(
          path: RoutePaths.faq, builder: (context, state) => const FAQPage()),
      GoRoute(
          path: RoutePaths.privacyPolicy,
          builder: (context, state) => const PrivacyPolicyPage()),
      GoRoute(
          path: RoutePaths.storeSettings,
          name: 'store_settings_page',
          builder: (context, state) => const StoreSettingsPage()),
      GoRoute(
          path: RoutePaths.deleteAccount,
          builder: (context, state) => const DeleteAccountPage()),
      GoRoute(
          path: RoutePaths.notifications,
          builder: (context, state) => const NotificationsPage()),
      GoRoute(
          path: RoutePaths.personalInfo,
          builder: (context, state) => const PersonalInformationPage()),
      GoRoute(
          path: RoutePaths.customerService,
          builder: (context, state) => const CustomerServicePage()),
      GoRoute(
          path: RoutePaths.adminCategories,
          builder: (context, state) => const AdminCategoriesScreen()),
      GoRoute(
          path: RoutePaths.adminNotifications,
          builder: (context, state) => const AdminNotificationsScreen()),
      GoRoute(
          path: RoutePaths.adminBanners,
          builder: (context, state) => const AdminBannersScreen()),
      GoRoute(
          path: RoutePaths.adminProductsControl,
          builder: (context, state) => const AdminProductsScreen()),
      GoRoute(
          path: RoutePaths.adminSettings,
          builder: (context, state) => const AdminSettingsScreen()),
      GoRoute(
          path: RoutePaths.adminReports,
          builder: (context, state) => const AdminReportsScreen()),
      GoRoute(
          path: RoutePaths.adminUsers,
          builder: (context, state) => const AdminUsersScreen()),
      GoRoute(
          path: RoutePaths.adminMerchants,
          builder: (context, state) => const AdminMerchantsScreen()),
      GoRoute(
        path: RoutePaths.adminCreateSubscription,
        builder: (context, state) => const AdminCreateSubscriptionScreen(),
      ),
      GoRoute(
        path: RoutePaths.customerTerms,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomerTermsPage(
            content: extra?['content'],
            version: extra?['version'],
            isMandatory: extra != null,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.merchantTerms,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MerchantTermsPage(
            content: extra?['content'],
            version: extra?['version'],
            isMandatory: extra != null,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.paymentSelection,
        builder: (context, state) {
          return PaymentSelectionScreen(
            amount: (pendingPaymentArgs['amount'] as num?)?.toDouble() ?? 0.0,
            packageName: pendingPaymentArgs['packageName'],
            onPaymentSuccess: pendingPaymentArgs['onPaymentSuccess']
                as Future<void> Function()?,
            planRank: (pendingPaymentArgs['planRank'] as num?)?.toInt(),
            currentPlanRank:
                (pendingPaymentArgs['currentPlanRank'] as num?)?.toInt(),
          );
        },
      ),
      GoRoute(
          path: '/admin-analytics-visits',
          builder: (context, state) => const AdminAnalyticsVisitsScreen()),
      GoRoute(
          path: '/admin-analytics-products',
          builder: (context, state) => const AdminAnalyticsProductsScreen()),
      GoRoute(
          path: '/admin-analytics-users',
          builder: (context, state) => const AdminAnalyticsUsersScreen()),
      GoRoute(
          path: '/admin-analytics-merchants',
          builder: (context, state) => const AdminAnalyticsMerchantsScreen()),
      GoRoute(
          path: RoutePaths.adminAnalyticsMerchantCategories,
          builder: (context, state) =>
              const AdminAnalyticsMerchantCategoriesScreen()),
      GoRoute(
          path: RoutePaths.adminAnalyticsProductCategories,
          builder: (context, state) =>
              const AdminAnalyticsProductCategoriesScreen()),
      GoRoute(
          path: '/admin-announcements',
          builder: (context, state) => const AdminAnnouncementsScreen()),
      GoRoute(
          path: RoutePaths.maintenance,
          builder: (context, state) => const MaintenanceScreen()),
      GoRoute(
        path: '/customer-profile/:userId',
        name: 'customer-profile',
        builder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          final extra = state.extra;
          final userData =
              extra is Map<String, dynamic> ? extra : <String, dynamic>{};
          return CustomerProfileScreen(userId: userId, userData: userData);
        },
      ),
    ],
  );
});
