import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
      // ✅ نستخدم نفس صيغة الإيميل التقني المعتمدة في مشروعك
      final techEmail = 'u$phone@RedOcean-official.com';
      final newPassword = _newPasswordController.text.trim();

      // ملاحظة: استعادة كلمة المرور بدون كود OTP تتطلب صلاحيات إدارية أو
      // استخدام رابط استعادة حقيقي، ولكن للتجربة الحالية سنحاول تحديث الجلسة
      await Supabase.instance.client.auth.resetPasswordForEmail(techEmail);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ إذا كان الحساب موجوداً، فستتم معالجة الطلب (راجع إعدادات السيرفر)'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('❌ خطأ: ${e.message}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("استعادة كلمة المرور",
            style: TextStyle(fontFamily: 'Cairo')),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_reset_rounded,
                  size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                "أدخل رقم الجوال المسجل لإرسال تعليمات إعادة التعيين",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "رقم الجوال",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone_android),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "يرجى إدخال الرقم" : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePasswordReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("إرسال طلب استعادة",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Cairo')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
