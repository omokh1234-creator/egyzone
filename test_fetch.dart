import 'lib/core/services/product_service.dart';

void main() async {
  try {
    print('Fetching products...');
    final products = await ProductService.fetchProducts();
    print('Fetched ${products.length} products.');
    if (products.isNotEmpty) {
      print('First product: ${products.first.name}');
    }

    print('\nFetching categories...');
    final categories = await ProductService.fetchCategories();
    print('Fetched ${categories.length} categories.');
    if (categories.isNotEmpty) {
      print(
          'First category: ${categories.first.name} with ${categories.first.subCategories.length} subcategories');
    }
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  }
}
