import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:RedOcean/core/routing/route_paths.dart';
import 'package:RedOcean/core/models/product_model.dart';
import '../widgets/product_card.dart';
import 'package:RedOcean/core/utils/category_icons.dart';

class SubCategoriesScreen extends StatefulWidget {
  final String parentId;
  final String categoryName;

  const SubCategoriesScreen({
    super.key,
    required this.parentId,
    required this.categoryName,
  });

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    const Color brandRed = Color(0xFFC21815);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.5,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.black, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(
            widget.categoryName,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          // ✅ نجلب اسم التصنيف الرئيسي مع كل تصنيف فرعي
          future: supabase
              .from('product_categories')
              .select('*, parent:parent_id(name)')
              .eq('parent_id', widget.parentId)
              .eq('is_visible', true)
              .order('name'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: brandRed));
            }
            final data = snapshot.data ?? [];
            if (data.isEmpty)
              return const Center(child: Text("لا توجد أقسام فرعية حالياً"));

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 0.85,
              ),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final String subName = item['name'] ?? 'قسم غير مسمى';
                // ✅ نستخدم اسم التصنيف الرئيسي للأيقونة
                final String parentName =
                    item['parent']?['name'] ?? widget.categoryName;

                return InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubCategoryItemsPage(
                          categoryId: item['id'],
                          categoryName: subName,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: () {
                              final img = CategoryIcons.getImage(subName);
                              return img != null
                                  ? Image.asset(img,
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.contain)
                                  : Icon(
                                      CategoryIcons.getSubIcon(
                                          subName, parentName),
                                      size: 28,
                                      color: brandRed);
                            }(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                      ),
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
}

class SubCategoryItemsPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const SubCategoryItemsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<SubCategoryItemsPage> createState() => _SubCategoryItemsPageState();
}

class _SubCategoryItemsPageState extends State<SubCategoryItemsPage> {
  final supabase = Supabase.instance.client;
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final data = await supabase
          .from('products')
          .select('*')
          .eq('category_id', widget.categoryId)
          .eq('is_available', true);

      if (mounted) {
        setState(() {
          _products =
              (data as List).map((p) => ProductModel.fromJson(p)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandRed = Color(0xFFC21815);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.5,
          title: Text(widget.categoryName,
              style: const TextStyle(
                  fontFamily: 'Cairo', color: Colors.black, fontSize: 16)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 5)
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث في ${widget.categoryName}...',
                    hintStyle:
                        const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: brandRed),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: brandRed))
                  : _products.isEmpty
                      ? const Center(
                          child: Text("لا توجد منتجات حالياً",
                              style: TextStyle(fontFamily: 'Cairo')))
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            return ProductCard(product: _products[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
