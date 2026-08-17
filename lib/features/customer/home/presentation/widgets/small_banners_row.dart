import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:red_market/core/routing/route_paths.dart';

class SmallBannersRow extends StatelessWidget {
  final PageController smallBannerController;

  const SmallBannersRow({
    super.key,
    required this.smallBannerController,
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('banners')
          .stream(primaryKey: ['id']).order('created_at'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox.shrink();

        // تصفية البنرات الصغيرة النشطة فقط من النوع "small"
        final smallBanners = snapshot.data!
            .where((b) => b['banner_type'] == 'small' && b['is_active'] == true)
            .toList();

        if (smallBanners.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 140, // تم تعديله قليلاً ليستوعب الـ Shadow بشكل مريح
          child: PageView.builder(
            controller: smallBannerController,
            itemCount: 10000,
            itemBuilder: (context, index) {
              final b = smallBanners[index % smallBanners.length];
              return _buildSmallBannerItem(context, b);
            },
          ),
        );
      },
    );
  }

  Widget _buildSmallBannerItem(
      BuildContext context, Map<String, dynamic> banner) {
    final String url = banner['image_url'] ?? '';

    return GestureDetector(
      onTap: () {
        // ✅ منطق الانتقال المحدث والمؤمن ضد أخطاء الـ UUID
        final String? productId = banner['product_id']?.toString();
        final String? merchantId = banner['merchant_id']?.toString();
        final String? categoryId = banner['category_id']?.toString();

        if (productId != null && productId.isNotEmpty) {
          context.push('/product-details/$productId');
        } else if (merchantId != null && merchantId.isNotEmpty) {
          context.push('/merchant-store/$merchantId');
        } else if (categoryId != null && categoryId.isNotEmpty) {
          context.push(
            RoutePaths.subCategories,
            extra: {
              'parentId': categoryId,
              'categoryName': banner['title'] ?? 'قسم خاص',
            },
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[50],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFC21815)),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
              : Container(color: Colors.grey[200]),
        ),
      ),
    );
  }
}
