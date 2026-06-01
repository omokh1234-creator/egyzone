class ProductBrand {
  final int brandId;
  final String name;
  final int? subCategoryId;

  ProductBrand({
    required this.brandId,
    required this.name,
    this.subCategoryId,
  });

  /// API schema: {brandId: int, name: string}
  factory ProductBrand.fromJson(Map<String, dynamic> json) {
    return ProductBrand(
      brandId: (json['brandId'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      subCategoryId: (json['subCategoryId'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'brandId': brandId,
        'name': name,
        'subCategoryId': subCategoryId,
      };
}

class ProductSubCategory {
  final int subCategoryId;
  final String name;
  final int? categoryId;
  final List<ProductBrand> brands;

  ProductSubCategory({
    required this.subCategoryId,
    required this.name,
    this.categoryId,
    List<ProductBrand>? brands,
  }) : brands = brands ?? [];

  /// API schema: {id: int, name: string} (from /api/Categories nested)
  /// OR         {subCategoryId: int, name: string, categoryId: int, category:{...}}
  factory ProductSubCategory.fromJson(Map<String, dynamic> json) {
    return ProductSubCategory(
      // API returns 'id' in nested format, 'subCategoryId' in flat format
      subCategoryId: (json['subCategoryId'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      categoryId: (json['categoryId'] as num?)?.toInt(),
      brands: (json['brands'] as List<dynamic>?)
              ?.map((e) => ProductBrand.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'subCategoryId': subCategoryId,
        'name': name,
        'categoryId': categoryId,
        'brands': brands.map((e) => e.toJson()).toList(),
      };
}


class ProductCategory {
  final int categoryId;
  final String name;
  final List<ProductSubCategory> subCategories;

  ProductCategory({
    required this.categoryId,
    required this.name,
    List<ProductSubCategory>? subCategories,
  }) : subCategories = subCategories ?? [];

  /// API schema: {id: int, name: string, subCategories:[{id, name}]}
  /// from /api/Categories (plain array, uses 'id' not 'categoryId')
  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      // API returns 'id' not 'categoryId' in /api/Categories response
      categoryId: (json['categoryId'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      subCategories: (json['subCategories'] as List<dynamic>?)
              ?.map((e) => ProductSubCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'name': name,
        'subCategories': subCategories.map((e) => e.toJson()).toList(),
      };
}
