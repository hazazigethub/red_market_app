import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:red_market/app/app.dart';
import 'package:go_router/go_router.dart'; // ✅ للإنتقال
import 'package:red_market/core/routing/route_paths.dart'; // ✅ للمسارات

class MerchantTermsPage extends ConsumerStatefulWidget {
  // ✅ إضافة البارامترات لاستقبال البيانات
  final String? content;
  final int? version;
  final bool isMandatory;

  const MerchantTermsPage({
    super.key,
    this.content,
    this.version,
    this.isMandatory = false,
  });

  @override
  ConsumerState<MerchantTermsPage> createState() => _MerchantTermsPageState();
}

class _MerchantTermsPageState extends ConsumerState<MerchantTermsPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = true;
  String _currentContent = "";

  @override
  void initState() {
    super.initState();
    // ✅ إذا كانت البيانات قادمة من الـ Router نستخدمها مباشرة
    if (widget.content != null) {
      _currentContent = widget.content!;
      _controller.text = _currentContent;
      _isLoading = false;
    } else {
      _fetchTerms();
    }
  }

  Future<void> _fetchTerms() async {
    try {
      final data = await Supabase.instance.client
          .from('terms_content')
          .select('content')
          .eq('type', 'merchant')
          .single();

      setState(() {
        _currentContent = data['content'] ?? "";
        _controller.text = _currentContent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching merchant terms: $e");
    }
  }

  // ✅ دالة قبول الشروط الخاصة بالتاجر
  Future<void> _acceptTerms() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client
          .from('profiles')
          .update({'accepted_terms_version': widget.version}).eq('id', userId);

      if (!mounted) return;

      // ✅ التوجه للوحة تحكم التاجر
      context.go(RoutePaths.merchantHome);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("حدث خطأ أثناء قبول شروط التاجر")),
      );
    }
  }

  Future<void> _saveTerms() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.rpc('increment_terms_version', params: {
        'term_type': 'merchant',
        'new_content': _controller.text,
      });

      setState(() {
        _currentContent = _controller.text;
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("تم تحديث شروط التجار وفرض الموافقة الجديدة"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("حدث خطأ أثناء حفظ شروط التاجر")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(userRoleProvider);
    final bool isSuperAdmin = userRole == 'super_admin';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          // ✅ إخفاء سهم الرجوع إذا كان الدخول إجبارياً
          automaticallyImplyLeading: !widget.isMandatory,
          elevation: 0,
          title: const Text("شروط وأحكام التاجر",
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          centerTitle: true,
          actions: [
            if (isSuperAdmin && !_isEditing)
              IconButton(
                icon: const Icon(Icons.edit_note_rounded,
                    color: Colors.blue, size: 28),
                onPressed: () => setState(() => _isEditing = true),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("اتفاقية استخدام التاجر",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo')),
                          const SizedBox(height: 15),
                          _isEditing
                              ? TextField(
                                  controller: _controller,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    hintText: "أدخل شروط التاجر الجديدة هنا...",
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                )
                              : Text(
                                  _currentContent,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.8,
                                      fontFamily: 'Cairo',
                                      color: Colors.black87),
                                ),
                          if (_isEditing) ...[
                            const SizedBox(height: 25),
                            _buildAdminEditButtons(),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ✅ زر الموافقة للتاجر في حالة الإجبار
                  if (widget.isMandatory)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _acceptTerms,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC21815),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("أوافق على شروط التاجر",
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildAdminEditButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveTerms,
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text("اعتماد التعديلات",
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() {
              _isEditing = false;
              _controller.text = _currentContent;
            }),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("إلغاء",
                style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
          ),
        ),
      ],
    );
  }
}
