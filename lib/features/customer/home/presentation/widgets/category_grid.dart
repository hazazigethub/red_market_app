import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:red_market/core/routing/route_paths.dart';
import 'package:red_market/core/utils/category_icons.dart';

class CategoryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final Function(Map<String, dynamic>)? onCategoryTap;

  const CategoryGrid({super.key, required this.categories, this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 115,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final String catName = cat['name'] ?? '';

          return Padding(
            padding: const EdgeInsets.only(left: 12),
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                if (onCategoryTap != null) {
                  onCategoryTap!(cat);
                } else {
                  context.push(
                    RoutePaths.subCategories,
                    extra: {
                      'parentId': cat['id'],
                      'categoryName': cat['name'],
                    },
                  );
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: CategoryIcons.getImage(catName) != null
                          ? Colors.transparent
                          : Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                              : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFC21815).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: CategoryIcons.getImage(catName) != null
                          ? Image.asset(
                              CategoryIcons.getImage(catName)!,
                              width: 70,
                              height: 70,
                              fit: BoxFit.contain,
                            )
                          : Icon(
                              CategoryIcons.getIcon(catName),
                              color: const Color(0xFFC21815),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      catName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
