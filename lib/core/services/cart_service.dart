import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final String _cartKey = 'user_cart_items';
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 1. إضافة منتج للسلة وحفظه محلياً
  Future<void> addToCart(Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> cart = await getCartItems();

    // التحقق إذا كان المنتج موجود مسبقاً لزيادة الكمية
    int index = cart.indexWhere((item) => item['id'] == product['id']);
    if (index != -1) {
      cart[index]['quantity'] = (cart[index]['quantity'] ?? 1) + 1;
    } else {
      product['quantity'] = 1;
      cart.add(product);
    }

    await prefs.setString(_cartKey, jsonEncode(cart));

    // ✅ جدولة التنبيهات بمجرد إضافة منتج جديد
    await _scheduleCartReminder();
  }

  // 2. جلب محتويات السلة
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    String? cartData = prefs.getString(_cartKey);
    if (cartData == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(cartData));
  }

  // 3. مسح السلة بعد إتمام الطلب
  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
    await _notificationsPlugin.cancelAll(); // إلغاء التنبيهات المجدولة
  }

  // 4. نظام التنبيهات المجدولة (بعد ساعة و 12 ساعة)
  Future<void> _scheduleCartReminder() async {
    // إعداد التنبيهات (يجب استدعاء initialize في بداية التطبيق)
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'cart_reminder_channel',
      'تنبيهات السلة',
      importance: Importance.max,
      priority: Priority.high,
    );

    // تنبيه بعد ساعة واحدة
    await _notificationsPlugin.zonedSchedule(
      101,
      'سلتك تنتظرك! 🛒',
      'لقد أضفت منتجات رائعة، هل ترغب في إكمال طلبك الآن؟',
      tz.TZDateTime.now(tz.local).add(const Duration(hours: 1)),
      const NotificationDetails(android: androidDetails),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // تنبيه بعد 12 ساعة
    await _notificationsPlugin.zonedSchedule(
      102,
      'لا تفوت الفرصة! 🔥',
      'المنتجات في سلتك قد تنفد، أتمم طلبك الآن لضمان توفرها.',
      tz.TZDateTime.now(tz.local).add(const Duration(hours: 12)),
      const NotificationDetails(android: androidDetails),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
