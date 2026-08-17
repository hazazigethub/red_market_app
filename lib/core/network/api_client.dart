import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ مزود العميل البرمجي (Provider) ليسهل الوصول إليه من أي مكان
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  late Dio _dio;

  // 🛑 ضع رابط السيرفر الخاص بك هنا
  static const String baseUrl = "https://api.yourdomain.com/api/v1";

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15), // وقت انتظار الاتصال
        receiveTimeout:
            const Duration(seconds: 15), // وقت انتظار استلام البيانات
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ✅ إضافة المراقب (Interceptor) للتعامل مع التوكن والأخطاء تلقائياً
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // جلب التوكن من الذاكرة المحلية (Shared Preferences) وإضافته لكل طلب
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // معالجة الأخطاء العامة هنا (مثل انتهاء الجلسة 401)
        if (e.response?.statusCode == 401) {
          // يمكن هنا إضافة منطق تسجيل الخروج التلقائي
        }
        return handler.next(e);
      },
    ));
  }

  // --- دالة لجلب البيانات (GET) ---
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // --- دالة لإرسال البيانات (POST) ---
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // --- دالة للتعديل (PUT) ---
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // --- دالة للحذف (DELETE) ---
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      rethrow;
    }
  }
}
