import 'package:overlay_support/overlay_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:RedOcean/core/routing/app_router.dart';
import 'package:RedOcean/main.dart'; // للوصول لـ appTypeProvider

final notificationsObserverProvider =
    Provider((ref) => NotificationsObserver(ref));

class NotificationsObserver {
  final Ref ref;
  final _supabase = Supabase.instance.client;
  bool _isListening = false; // لمنع التكرار

  NotificationsObserver(this.ref);

  void startListening() {
    if (_isListening) return; // إذا كان يعمل مسبقاً لا تفعل شيئاً

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _isListening = true;

    // ملاحظة: أضفنا فلترة للوقت لكي لا يظهر الإشعارات القديمة عند تشغيل التطبيق
    final now = DateTime.now().toIso8601String();

    _supabase
        .from('notifications_log')
        .stream(primaryKey: ['id'])
        // فلترة مباشرة من السوبابيس لجلب الإشعارات المرسلة فقط
        .eq('status', 'sent')
        .order('created_at', ascending: false)
        .limit(1)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            final notification = data.first;

            // التحقق من الوقت (لضمان عدم ظهور إشعارات قديمة جداً عند تشغيل التطبيق)
            final createdAt = DateTime.parse(notification['created_at']);
            if (createdAt.isBefore(
                DateTime.now().subtract(const Duration(seconds: 30)))) return;

            final String targetType = notification['target_type'];
            final String? targetId = notification['target_id'];
            final String? segment = notification['segment_filter'];

            bool shouldShow = false;

            // منطق الفلترة الذكي
            if (targetType == 'all') {
              shouldShow = true;
            } else if (targetType == 'specific' && targetId == userId) {
              shouldShow = true;
            } else if (targetType == 'segment' && segment != null) {
              final appType = ref.read(appTypeProvider);
              // إذا كان الإشعار للمتاجر والمستخدم تاجر
              if (segment.contains('merchants') &&
                  appType == AppType.merchant) {
                shouldShow = true;
              }
              // إذا كان الإشعار للعملاء والمستخدم عميل
              else if (segment.contains('users') &&
                  appType == AppType.customer) {
                shouldShow = true;
              }
            }

            if (shouldShow) {
              _showTopNotification(notification);
            }
          }
        });
  }

  void _showTopNotification(Map<String, dynamic> data) {
    late OverlaySupportEntry entry;

    entry = showSimpleNotification(
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          entry.dismiss();

          // ✅ التعديل الجوهري: التوجه للمسار الصحيح حسب نوع المستخدم
          final appType = ref.read(appTypeProvider);

          if (appType == AppType.customer) {
            ref.read(routerProvider).push('/customer/notifications');
          } else if (appType == AppType.merchant) {
            ref.read(routerProvider).push('/merchant/notifications');
          }

          debugPrint("🚀 التوجه لصفحة إشعارات الـ ${appType.name}");
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data['title'] ?? 'إشعار جديد',
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14),
            ),
            Text(
              data['body'] ?? '',
              style: const TextStyle(
                  fontFamily: 'Cairo', fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      leading: const Icon(Icons.notifications_active, color: Colors.white),
      background: const Color(0xFFC21815),
      duration: const Duration(seconds: 5),
    );
  }
}
