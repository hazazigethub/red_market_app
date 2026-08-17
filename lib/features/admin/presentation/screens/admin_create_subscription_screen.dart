import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:red_market/features/admin/presentation/screens/discount_codes_screen.dart';

class AdminCreateSubscriptionScreen extends StatefulWidget {
  const AdminCreateSubscriptionScreen({super.key});

  @override
  State<AdminCreateSubscriptionScreen> createState() =>
      _AdminCreateSubscriptionScreenState();
}

class _AdminCreateSubscriptionScreenState
    extends State<AdminCreateSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _packageNameController =
      TextEditingController(text: "الباقة الكلاسيكية");
  final TextEditingController _priceController =
      TextEditingController(text: "49");
  final TextEditingController _promoCodeController = TextEditingController();
  final TextEditingController _discountPercentController =
      TextEditingController();
  final TextEditingController _limitController =
      TextEditingController(text: "100");
  final TextEditingController _reelsLimitController =
      TextEditingController(text: "5");
  final TextEditingController _rankController =
      TextEditingController(text: "1");
  final TextEditingController _referralBonusController =
      TextEditingController(text: "0");
  bool _hasBasicReports = true;
  bool _hasDetailedReports = false;
  bool _isPriceLocked = false;
  bool _hasPartialAdminAccess = false;
  bool _hasFullAdminAccess = false;
  String _durationPlan = "30";
  DateTime? _expiryDate;
  bool _isLoading = false;

  // متغير للتحكم في التبويب النشط داخلياً
  int _activeInternalTab = 0;

  final Color brandRed = const Color(0xFFC21815);

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final planResponse = await supabase
          .from('subscription_plans')
          .insert({
            'name': _packageNameController.text,
            'price': double.parse(_priceController.text),
            'duration_days': int.parse(_durationPlan),
            'product_limit': int.parse(_limitController.text),
            'rank': int.parse(_rankController.text),
            'discount_percent': _discountPercentController.text.isNotEmpty
                ? int.parse(_discountPercentController.text)
                : 0,
            'reels_limit': int.parse(_reelsLimitController.text),
            'has_basic_reports': _hasBasicReports,
            'has_detailed_reports': _hasDetailedReports,
            'is_price_locked': _isPriceLocked,
            'has_partial_access': _hasPartialAdminAccess,
            'has_full_access': _hasFullAdminAccess,
            'referral_bonus': double.parse(_referralBonusController.text.isEmpty
                ? "0"
                : _referralBonusController.text),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      if (_promoCodeController.text.isNotEmpty) {
        await supabase.from('promo_codes').insert({
          'code': _promoCodeController.text,
          'discount_percent': int.parse(
              _discountPercentController.text.isNotEmpty
                  ? _discountPercentController.text
                  : "0"),
          'plan_id': planResponse['id'],
          'expiry_date': _expiryDate?.toIso8601String(),
          'is_active': true,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("تم إنشاء الباقة بنجاح",
                  style: TextStyle(fontFamily: 'Cairo'))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("لوحة التحكم بالاشتراكات",
              style:
                  TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          backgroundColor: brandRed,
          centerTitle: true,
          elevation: 0,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: brandRed))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildHeaderCard(
                              "إنشاء باقة", Icons.add_rounded, true, () {}),
                          const SizedBox(width: 10),
                          _buildHeaderCard(
                              "الباقات الحالية", Icons.grid_view_rounded, false,
                              () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const CurrentPlansScreen()));
                          }),
                          const SizedBox(width: 10),
                          _buildHeaderCard("أكواد الخصم",
                              Icons.confirmation_number_rounded, false, () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        DiscountCodesScreen()));
                          }),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 10))
                          ],
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("نوع الباقة (اسم الباقة):",
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _packageNameController,
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.grey[200]!),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: brandRed),
                                ),
                              ),
                            ),
                            const Divider(height: 40, thickness: 0.5),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text("\$",
                                    style: TextStyle(
                                        fontSize: 22,
                                        color: brandRed.withOpacity(0.7),
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 120,
                                  child: TextFormField(
                                    controller: _priceController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => setState(() {}),
                                    style: const TextStyle(
                                        fontSize: 44,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1),
                                    decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true),
                                  ),
                                ),
                                Text(
                                    _durationPlan == "30" ? " / شهر" : " / سنة",
                                    style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                        fontFamily: 'Cairo')),
                              ],
                            ),
                            const SizedBox(height: 25),
                            const Text("صلاحية الباقة:",
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                _buildDurationOption("30 يوم", "30"),
                                const SizedBox(width: 12),
                                _buildDurationOption("365 يوم", "365"),
                              ],
                            ),
                            const Divider(height: 40, thickness: 0.5),
                            _buildInternalInput(Icons.inventory_2_outlined,
                                "حد المنتجات:", _limitController,
                                isNumber: true),
                            _buildInternalInput(Icons.videocam_outlined,
                                "عدد الريلز المتاح:", _reelsLimitController,
                                isNumber: true),
                            _buildInternalInput(Icons.star_outline_rounded,
                                "رتبة الباقة (للترقية):", _rankController,
                                isNumber: true),
                            _buildInternalInput(Icons.card_giftcard_rounded,
                                "خصم دعوة تاجر (\$):", _referralBonusController,
                                isNumber: true, isRequired: false),
                            _buildInternalInput(
                                Icons.confirmation_number_outlined,
                                "كود الخصم:",
                                _promoCodeController,
                                isRequired: false),
                            _buildInternalInput(Icons.percent_rounded,
                                "نسبة الخصم:", _discountPercentController,
                                isNumber: true, isRequired: false),
                            const SizedBox(height: 15),
                            // ✅ مضاف: switches التقارير مع وصف توضيحي
                            _buildSwitchWithDescription(
                                "تقارير الإجماليات (الكلاسيكية)",
                                "يظهر للتاجر: إجمالي زيارات المتجر + إجمالي تفاعلات المنتجات + إجمالي تفاعلات الريلز",
                                _hasBasicReports,
                                (v) => setState(() {
                                      _hasBasicReports = v;
                                      if (!v) _hasDetailedReports = false;
                                    })),
                            _buildSwitchWithDescription(
                                "تقارير تفصيلية (البريميوم)",
                                "يظهر للتاجر: كل الإجماليات + تفاصيل كل تفاعل + الضغط على كل خانة لرؤية المنتجات والريلز",
                                _hasDetailedReports,
                                (v) => setState(() {
                                      _hasDetailedReports = v;
                                      if (v) _hasBasicReports = true;
                                    })),
                            _buildSwitchOption(
                                "تجديد بنفس العرض (السعر الثابت)",
                                _isPriceLocked,
                                (v) => setState(() => _isPriceLocked = v)),
                            _buildSwitchOption(
                                "وصول جزئي للوحة التحكم",
                                _hasPartialAdminAccess,
                                (v) => setState(() {
                                      _hasPartialAdminAccess = v;
                                      if (v)
                                        _hasFullAdminAccess =
                                            false; // لو فعلت الجزئي، يطفي الكامل تلقائياً
                                    })),
                            _buildSwitchOption(
                                "وصول كامل للوحة التحكم",
                                _hasFullAdminAccess,
                                (v) => setState(() {
                                      _hasFullAdminAccess = v;
                                      if (v)
                                        _hasPartialAdminAccess =
                                            false; // لو فعلت الكامل، يطفي الجزئي تلقائياً
                                    })),
                            const SizedBox(height: 35),
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: _savePlan,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandRed,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18)),
                                ),
                                child: const Text("حفظ ونشر الباقة",
                                    style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ودجت للتبديل بين التبويبات الداخلية
  Widget _buildInternalTabTrigger(int index, String label) {
    bool isSelected = _activeInternalTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeInternalTab = index),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? brandRed : Colors.grey)),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 20,
              color: brandRed,
            )
        ],
      ),
    );
  }

  Widget _buildSwitchOption(
      String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title,
          style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 13, color: Colors.black87)),
      value: value,
      activeColor: brandRed,
      contentPadding: EdgeInsets.zero,
      onChanged: onChanged,
    );
  }

  // ✅ مضاف: switch مع وصف توضيحي
  Widget _buildSwitchWithDescription(
      String title, String description, bool value, Function(bool) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(title,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          value: value,
          activeColor: brandRed,
          contentPadding: EdgeInsets.zero,
          onChanged: onChanged,
        ),
        if (value)
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: brandRed.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: brandRed.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: brandRed, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(description,
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Colors.grey[700],
                            height: 1.5)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInternalInput(
      IconData icon, String label, TextEditingController controller,
      {bool isNumber = false, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: brandRed.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(icon, color: brandRed, size: 18),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Cairo', fontSize: 14, color: Colors.black54)),
          const SizedBox(width: 15),
          Expanded(
            child: TextFormField(
              controller: controller,
              onChanged: (v) => setState(() {}),
              keyboardType:
                  isNumber ? TextInputType.number : TextInputType.text,
              style: const TextStyle(
                  fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[200]!)),
              ),
              validator: (v) =>
                  isRequired && (v == null || v.isEmpty) ? "مطلوب" : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
      String title, IconData icon, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: isActive ? brandRed : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: brandRed.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ]
                : [],
            border:
                Border.all(color: isActive ? brandRed : Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon, color: isActive ? Colors.white : brandRed, size: 28),
              const SizedBox(height: 10),
              Text(title,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isActive ? Colors.white : Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationOption(String label, String value) {
    bool isSelected = _durationPlan == value;
    return Expanded(
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () => setState(() => _durationPlan = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? brandRed : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal)),
          ),
        ),
      ),
    );
  }
}

class CurrentPlansScreen extends StatelessWidget {
  const CurrentPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color brandRed = const Color(0xFFC21815);
    final supabase = Supabase.instance.client;

    Future<void> _togglePlanStatus(String id, bool currentStatus) async {
      await Supabase.instance.client
          .from('subscription_plans')
          .update({'is_active': !currentStatus}).match({'id': id});
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("الباقات المتاحة حالياً",
              style:
                  TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          backgroundColor: brandRed,
          centerTitle: true,
          elevation: 0,
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase
              .from('subscription_plans')
              .stream(primaryKey: ['id']).order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: brandRed));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                  child: Text("لا توجد باقات منشورة بعد",
                      style: TextStyle(fontFamily: 'Cairo')));
            }

            final plans = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                final bool isActive = plan['is_active'] ?? true;
                final double originalPrice =
                    double.tryParse(plan['price'].toString()) ?? 0.0;
                final int discountPercent = plan['discount_percent'] ?? 0;
                final double newPrice =
                    originalPrice - (originalPrice * discountPercent / 100);

                return Container(
                  margin: const EdgeInsets.only(bottom: 25),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(plan['name'].toString().toUpperCase(),
                              style: TextStyle(
                                  color: brandRed,
                                  fontWeight: ui.FontWeight.w800,
                                  fontFamily: 'Cairo',
                                  fontSize: 15)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              isActive ? "نشط" : "غير نشط",
                              style: TextStyle(
                                  color: isActive ? Colors.green : Colors.grey,
                                  fontSize: 11,
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text("\$",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: brandRed.withOpacity(0.7),
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 5),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "${discountPercent > 0 ? newPrice.toStringAsFixed(1) : originalPrice}",
                                style: TextStyle(
                                    fontSize: 42,
                                    color: brandRed,
                                    letterSpacing: -1,
                                    fontWeight: FontWeight.w900),
                              ),
                              if (discountPercent > 0) ...[
                                const SizedBox(width: 10),
                                Text(
                                  "\$$originalPrice",
                                  style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough),
                                ),
                              ],
                            ],
                          ),
                          Text(
                              plan['duration_days'] >= 365
                                  ? " / سنة"
                                  : " / شهر",
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                  fontFamily: 'Cairo')),
                        ],
                      ),
                      const Divider(height: 40, thickness: 0.5),
                      _buildMerchantFeature(Icons.check_circle_outline_rounded,
                          "حد المنتجات: ${plan['product_limit']}", brandRed),
                      _buildMerchantFeature(Icons.videocam_outlined,
                          "عدد الريلز: ${plan['reels_limit'] ?? 0}", brandRed),
                      if (plan['is_price_locked'] == true)
                        _buildMerchantFeature(Icons.lock_outline,
                            "تثبيت السعر عند التجديد", brandRed),
                      if (plan['has_partial_access'] == true)
                        _buildMerchantFeature(
                            Icons.admin_panel_settings_outlined,
                            "وصول جزئي للوحة التحكم",
                            brandRed),
                      if (plan['has_full_access'] == true)
                        _buildMerchantFeature(Icons.verified_user_outlined,
                            "وصول كامل للوحة التحكم", brandRed),
                      // ✅ مضاف: وصف واضح لنوع التقارير
                      if (plan['has_basic_reports'] == true &&
                          plan['has_detailed_reports'] != true)
                        _buildMerchantFeature(
                            Icons.analytics_outlined,
                            "تقارير الإجماليات (إجمالي الزيارات والتفاعلات)",
                            brandRed),
                      if (plan['has_detailed_reports'] == true)
                        _buildMerchantFeature(
                            Icons.query_stats,
                            "تقارير تفصيلية كاملة (إجماليات + تفاصيل كل تفاعل)",
                            brandRed),
                      if (plan['referral_bonus'] != null &&
                          plan['referral_bonus'] > 0)
                        _buildMerchantFeature(
                            Icons.card_giftcard_rounded,
                            "مكافأة دعوة تاجر: \$${plan['referral_bonus']}",
                            brandRed),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _togglePlanStatus(
                                  plan['id'].toString(), isActive),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isActive
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                foregroundColor: isActive
                                    ? Colors.orange[800]
                                    : Colors.green[800],
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                isActive ? "تعطيل" : "تفعيل",
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showDeleteDialog(
                                  context, plan['id'].toString(), plan['name']),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.red.shade100),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text("حذف",
                                  style: TextStyle(
                                      color: Colors.red, fontFamily: 'Cairo')),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMerchantFeature(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: color.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}

Future<void> _showDeleteDialog(
    BuildContext context, String planId, String planName) async {
  final supabase = Supabase.instance.client;

  return showDialog(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: ui.TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("تأكيد الحذف",
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text(
            "هل أنت متأكد من حذف باقة ($planName)؟ لا يمكن التراجع عن هذا الإجراء."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء",
                style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, elevation: 0),
            onPressed: () async {
              await supabase
                  .from('subscription_plans')
                  .delete()
                  .match({'id': planId});
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("حذف الآن",
                style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
          ),
        ],
      ),
    ),
  );
}
