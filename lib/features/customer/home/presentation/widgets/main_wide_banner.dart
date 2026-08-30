import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:red_market/core/routing/route_paths.dart';

class MainWideBanner extends StatelessWidget {
  final PageController bannerController;

  const MainWideBanner({
    super.key,
    required this.bannerController,
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('banners')
          .stream(primaryKey: ['id']).order('created_at'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildPlaceholder();
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return _buildPlaceholder();

        // تصفية البنرات النشطة من النوع "wide"
        final active = snapshot.data!
            .where((b) => b['banner_type'] == 'wide' && b['is_active'] == true)
            .toList();

        if (active.isEmpty) return _buildPlaceholder();

        return SizedBox(
          height: 190, // ارتفاع متناسق مع التصميم
          child: PageView.builder(
            controller: bannerController,
            itemCount: 10000,
            itemBuilder: (context, index) {
              final b = active[index % active.length];
              return _buildBannerItem(context, b);
            },
          ),
        );
      },
    );
  }

  Widget _buildBannerItem(BuildContext context, Map<String, dynamic> banner) {
    final String imageUrl = banner['image_url'] ?? '';

    return GestureDetector(
      onTap: () {
        // ✅ منطق الانتقال المحدث لحل مشكلة الـ UUID والـ Router
        final String? productId = banner['product_id']?.toString();
        final String? merchantId = banner['merchant_id']?.toString();
        final String? categoryId = banner['category_id']?.toString();

        if (productId != null && productId.isNotEmpty) {
          // الانتقال لصفحة المنتج باستخدام المسار الديناميكي
          context.push('/product-details/$productId');
        } else if (merchantId != null && merchantId.isNotEmpty) {
          // الانتقال لصفحة المتجر باستخدام المسار الديناميكي الذي يدعم الـ ID
          context.push('/merchant-store/$merchantId');
        } else if (categoryId != null && categoryId.isNotEmpty) {
          context.push(
            RoutePaths.subCategories,
            extra: {
              'parentId': categoryId,
              'categoryName': banner['title'] ?? 'العرض',
            },
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[100],
                      child: const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFC21815))),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image,
                        color: Colors.grey, size: 40),
                  ),
                )
              : Container(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() => Container(
      height: 140,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
              colors: [Color(0xFFC21815), Color(0xFFE62E04)])),
      child: const Center(
          child: Text(" رد ماركت ",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo'))));
}
