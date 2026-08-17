import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:RedOcean/core/routing/route_paths.dart';
import 'package:RedOcean/app/app.dart' as app_internal;
import 'package:RedOcean/app/app_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:RedOcean/core/widgets/price_widget.dart';

class PaymentSelectionScreen extends ConsumerStatefulWidget {
  final double amount;
  final String packageName;
  final Future<void> Function()? onPaymentSuccess;
  final int? planRank; // ✅ هذا السطر موجود؟
  final int? currentPlanRank; // ✅ هذا السطر موجود؟

  const PaymentSelectionScreen({
    super.key,
    required this.amount,
    required this.packageName,
    this.onPaymentSuccess,
    this.planRank, // ✅ هذا السطر موجود؟
    this.currentPlanRank, // ✅ هذا السطر موجود؟
  });

  @override
  ConsumerState<PaymentSelectionScreen> createState() =>
      _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState
    extends ConsumerState<PaymentSelectionScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardHolderNameController =
      TextEditingController();
  final TextEditingController _promoCodeController = TextEditingController();

  // متغيرات للتحكم في الخصم
  double _discountPercentage = 0.0;
  bool _isDiscountApplied = false;

  // حساب المبلغ النهائي بعد الخصم
  double get _finalAmount {
    if (_discountPercentage <= 0) return widget.amount;
    double calculated =
        widget.amount - (widget.amount * (_discountPercentage / 100));
    return calculated < 0 ? 0 : calculated;
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderNameController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  // دالة التحقق من كود الخصم المحدثة لتطابق مسميات قاعدة البيانات الفعلية
  Future<void> _applyPromoCode() async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // استعلام مباشر للتأكد من المسميات (code, is_active, discount_percent, expiry_date)
      final response = await supabase
          .from('promo_codes')
          .select()
          .eq('code', code)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        throw "كود الخصم غير صحيح أو غير فعال حالياً";
      }

      // التحقق من تاريخ الانتهاء (expiry_date)
      if (response['expiry_date'] != null) {
        DateTime expiryDate = DateTime.parse(response['expiry_date']);
        if (expiryDate.isBefore(DateTime.now())) {
          throw "عذراً، انتهت صلاحية كود الخصم هذا";
        }
      }

      // استخراج نسبة الخصم باستخدام المسمى الصحيح (discount_percent)
      final discountValue =
          double.tryParse(response['discount_percent'].toString()) ?? 0.0;

      setState(() {
        _discountPercentage = discountValue;
        _isDiscountApplied = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("تم تطبيق الخصم بنجاح ✅",
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(e.toString(), style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "إتمام الدفع للاشتراك",
          style: TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC21815)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPackageSummary(),
                    const SizedBox(height: 30),
                    // إظهار نموذج البطاقة فقط إذا كان المبلغ أكبر من صفر
                    if (_finalAmount > 0) ...[
                      const Text(
                        "بيانات بطاقة الدفع (مدى / فيزا):",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 15),
                      _buildCardForm(),
                      const SizedBox(height: 25),
                    ] else ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  color: Colors.green),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "هذا الاشتراك مجاني بالكامل، يمكنك التفعيل مباشرة دون الحاجة لبيانات دفع.",
                                  style: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],
                    const Text(
                      "هل لديك كود خصم؟",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo'),
                    ),
                    const SizedBox(height: 10),
                    _buildPromoCodeField(),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPackageSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC21815).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC21815).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("الباقة المختارة:",
                  style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 12, color: Colors.grey)),
              Text(widget.packageName,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("المبلغ الإجمالي:",
                  style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 12, color: Colors.grey)),
              if (_isDiscountApplied)
                PriceWidget(
                  price: widget.amount,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              PriceWidget(
                price: _finalAmount,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        TextFormField(
          controller: _cardHolderNameController,
          keyboardType: TextInputType.name,
          decoration:
              _inputDecoration("الاسم المكتوب على البطاقة", Icons.person),
          validator: (value) =>
              (value == null || value.isEmpty) ? "يرجى إدخال الاسم" : null,
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
          decoration: _inputDecoration(
              "رقم البطاقة المكون من 16 رقم", Icons.credit_card),
          validator: (value) =>
              (value?.length ?? 0) < 16 ? "الرقم غير مكتمل" : null,
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryDateController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: _inputDecoration("MM/YY", Icons.calendar_today),
                validator: (value) => value!.isEmpty ? "مطلوب" : null,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [LengthLimitingTextInputFormatter(3)],
                decoration: _inputDecoration("CVV", Icons.lock),
                validator: (value) => (value?.length ?? 0) < 3 ? "خطأ" : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromoCodeField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _promoCodeController,
            enabled: !_isDiscountApplied,
            decoration: _inputDecoration("أدخل كود الخصم", Icons.local_offer),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _isDiscountApplied ? null : _applyPromoCode,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC21815),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
          child: Text(_isDiscountApplied ? "تم" : "تطبيق",
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        )
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          fontFamily: 'Cairo', fontSize: 13, color: Colors.grey),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFFC21815)),
      filled: true,
      fillColor: Colors.grey[50],
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC21815))),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red)),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC21815),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        onPressed: _isLoading ? null : _processPayment,
        child: Text(
          _finalAmount == 0
              ? "تفعيل الاشتراك المجاني"
              : "تأكيد الدفع والاشتراك",
          style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo'),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    // ✅ مضاف: تحقق أخير قبل الدفع
    if (widget.planRank != null && widget.currentPlanRank != null) {
      if (widget.planRank! <= widget.currentPlanRank!) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("لا يمكن الاشتراك في نفس الباقة أو باقة أدنى",
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // عدم تفعيل الـ Validation إذا كان المبلغ 0 لأن الحقول مخفية
    if (_finalAmount > 0) {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. الانتظار الوهمي لعملية الدفع
      if (_finalAmount > 0) {
        await Future.delayed(const Duration(seconds: 2));
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // 2. التنفيذ الفعلي لتحديث سوبابيس باستخدام العمود المحدث: is_subscription_active
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('profiles').update({
          'package_name': widget.packageName,
          'is_subscription_active': true,
          'subscription_date': DateTime.now().toIso8601String(),
        }).eq('id', user.id);

        await supabase.from('merchants').update({
          'is_subscription_active': true,
        }).eq('id', user.id);
      }

      // 3. استدعاء الدالة الأصلية إذا كانت موجودة
      if (widget.onPaymentSuccess != null) {
        await widget.onPaymentSuccess!();
      }

      if (!mounted) return;

      setState(() => _isLoading = false);

      // 4. الانتقال النهائي
      context.go(RoutePaths.home);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("مبروك! تم تفعيل اشتراكك بنجاح ✅",
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Color(0xFFC21815),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("خطأ في العملية: $e"), backgroundColor: Colors.red));
      }
    }
  }
}
