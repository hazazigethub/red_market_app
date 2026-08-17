import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:RedOcean/core/routing/route_paths.dart';
import 'package:RedOcean/features/auth/presentation/register_screen.dart';
import 'package:RedOcean/app/app_providers.dart';
import 'package:RedOcean/features/merchant/dashboard/presentation/pages/store_settings_page.dart';

class MerchantRegisterScreen extends ConsumerStatefulWidget {
  const MerchantRegisterScreen({super.key});

  @override
  ConsumerState<MerchantRegisterScreen> createState() =>
      _MerchantRegisterScreenState();
}

class _MerchantRegisterScreenState
    extends ConsumerState<MerchantRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _crNumberController = TextEditingController();

  bool _isTermsAccepted = false;
  String? _selectedStoreCategory;
  File? _crImageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _crNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _crImageFile = File(image.path));
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isTermsAccepted) {
      _showError("⚠️ يرجى الموافقة على الشروط والأحكام أولاً");
      return;
    }

    if (_crImageFile == null) {
      _showError("⚠️ صورة السجل التجاري مطلوبة");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("⚠️ كلمات المرور غير متطابقة");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final String rawPhone = _phoneController.text.trim();
      final String cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
      final String techEmail = 'u$cleanPhone@RedOcean-official.com';
      final String password = _passwordController.text.trim();

      String? imageUrl;

      // 1. رفع صورة السجل التجاري أولاً لضمان وجود الرابط
      final fileExt = _crImageFile!.path.split('.').last;
      final fileName =
          'cr_${cleanPhone}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage.from('merchants_docs').upload(
          fileName, _crImageFile!,
          fileOptions: const FileOptions(contentType: 'image/jpeg'));

      imageUrl = supabase.storage.from('merchants_docs').getPublicUrl(fileName);

      final response = await supabase.auth.signUp(
        email: techEmail,
        password: password,
        data: {
          'role': 'merchant',
          'full_name': _nameController.text.trim(),
        },
      );
      int latestTermsVersion = 0;
      try {
        final termsData = await supabase
            .from('terms_content')
            .select('version')
            .eq('type', 'merchant')
            .maybeSingle();
        latestTermsVersion = (termsData?['version'] as num?)?.toInt() ?? 0;
      } catch (_) {}
      final user = response.user;
      if (user != null) {
        await supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': _nameController.text.trim(),
          'phone_number': cleanPhone,
          'email_contact': _emailController.text.trim(),
          'role': 'merchant',
          'is_banned': false,
          'is_subscription_active': false,
          'is_permanent_ban': false,
          'created_at': DateTime.now().toIso8601String(),
          'accepted_terms_version': latestTermsVersion,
        });

        // 4. تحديث جدول التجار (merchants) بالمعلومات التفصيلية
        await supabase.from('merchants').upsert({
          'id': user.id,
          'owner_id': user.id,
          'store_name': _nameController.text.trim(),
          'phone_number': cleanPhone,
          'email_contact': _emailController.text.trim(),
          'password': password,
          'cr_number': _crNumberController.text.trim(),
          'cr_image_url': imageUrl,
          'store_category_id': _selectedStoreCategory,
          'is_subscription_active': false,
          'is_banned': false,
          'is_permanent_ban': false,
          'created_at': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('✅ تم إنشاء حساب التاجر بنجاح!'),
                backgroundColor: Color(0xFF4CAF50)),
          );
          ref.read(userRoleProvider.notifier).state = 'merchant';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go(RoutePaths.storeSettings);
          });
        }
      }
    } on AuthException catch (e) {
      setState(() => _isLoading = false);
      _showError("خطأ في التسجيل: ${e.message}");
    } catch (e) {
      isRegisteringInProgress = false;
      _showError("حدث خطأ في مزامنة البيانات: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activeColor = const Color(0xFFC21815);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text("إنشاء حساب تاجر",
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLabel("اسم المطعم / المتجر"),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontFamily: 'Cairo'),
                  decoration: _inputDecoration(
                      hint: "مثال: بيتزا هت", icon: Icons.store_outlined),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? "الاسم مطلوب" : null,
                ),
                const SizedBox(height: 15),
                _buildLabel("رقم هاتف التواصل"),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontFamily: 'Cairo'),
                  decoration: _inputDecoration(
                      hint: "05xxxxxxxx", icon: Icons.phone_android),
                  validator: (val) => (val == null || val.length < 9)
                      ? "رقم الهاتف مطلوب"
                      : null,
                ),
                const SizedBox(height: 15),
                _buildLabel("تصنيف النشاط التجاري"),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: Supabase.instance.client
                      .from('store_categories')
                      .select()
                      .eq('is_visible', true),
                  builder: (context, snapshot) {
                    return DropdownButtonFormField<String>(
                      value: _selectedStoreCategory,
                      style: const TextStyle(
                          fontFamily: 'Cairo', color: Colors.black),
                      decoration: _inputDecoration(
                          hint: "اختر نوع المتجر",
                          icon: Icons.category_outlined),
                      items: (snapshot.data ?? []).map((cat) {
                        return DropdownMenuItem(
                          value: cat['id'].toString(),
                          child: Text(cat['name'],
                              style: const TextStyle(fontFamily: 'Cairo')),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedStoreCategory = val),
                      validator: (val) =>
                          val == null ? "يرجى اختيار تصنيف" : null,
                    );
                  },
                ),
                const SizedBox(height: 15),
                _buildLabel("البريد الإلكتروني الرسمي"),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontFamily: 'Cairo'),
                  decoration: _inputDecoration(
                      hint: "merchant@example.com", icon: Icons.email_outlined),
                  validator: (val) => (val == null || !val.contains('@'))
                      ? "البريد الإلكتروني غير صحيح"
                      : null,
                ),
                const SizedBox(height: 15),
                _buildLabel("كلمة السر"),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontFamily: 'Cairo'),
                  decoration: _inputDecoration(
                    hint: "**********",
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) => (val == null || val.length < 6)
                      ? "كلمة السر قصيرة جداً"
                      : null,
                ),
                const SizedBox(height: 15),
                _buildLabel("تأكيد كلمة السر"),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(fontFamily: 'Cairo'),
                  decoration: _inputDecoration(
                    hint: "**********",
                    icon: Icons.lock_reset_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (val) => (val != _passwordController.text)
                      ? "كلمات المرور غير متطابقة"
                      : null,
                ),
                const SizedBox(height: 15),
                _buildLabel("رقم السجل التجاري"),
                TextFormField(
                  controller: _crNumberController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontFamily: 'Cairo'),
                  decoration: _inputDecoration(
                      hint: "10xxxxxxxx",
                      icon: Icons.confirmation_number_outlined),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? "رقم السجل مطلوب" : null,
                ),
                const SizedBox(height: 20),
                _buildLabel("صورة السجل التجاري"),
                InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: _pickImage,
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey[50],
                      border: Border.all(
                          color: _crImageFile == null
                              ? Colors.grey.shade300
                              : activeColor,
                          width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _crImageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_crImageFile!, fit: BoxFit.cover))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Icon(Icons.cloud_upload_outlined,
                                    size: 40, color: Colors.grey[400]),
                                Text("ارفع صورة السجل التجاري",
                                    style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: Colors.grey[600]))
                              ]),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: _isTermsAccepted,
                      activeColor: activeColor,
                      onChanged: (val) =>
                          setState(() => _isTermsAccepted = val ?? false),
                    ),
                    const Text("أوافق على ",
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    GestureDetector(
                      onTap: () => context.push(RoutePaths.merchantTerms),
                      child: Text("الشروط والأحكام الخاصة بالتجار",
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: activeColor,
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_isTermsAccepted)
                        ? null
                        : _handleRegister,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("إنشاء حساب تاجر",
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text("العودة لتسجيل حساب عميل",
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: activeColor)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 5),
      child: Text(text,
          style: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)));

  InputDecoration _inputDecoration(
      {required String hint, IconData? icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon:
          icon != null ? Icon(icon, size: 20, color: Colors.grey[600]) : null,
      suffixIcon: suffixIcon,
      hintStyle:
          TextStyle(fontFamily: 'Cairo', color: Colors.grey[400], fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC21815), width: 1.5)),
    );
  }
}
