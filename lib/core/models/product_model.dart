import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/auth_service.dart';

/// Represents a product as returned by /api/Products and /api/Products/{id}.
///
/// API Schema (swagger):
/// {
///   productId: int,
///   name: string,
///   description: string,
///   price: double,
///   stock: int?,
///   sellerId: int?,
///   subCategoryId: int?,
///   brandId: int?,
///   isApproved: bool,
///   isDeleted: bool,
///   imageUrl: string?,           ← primary image (flat field)
///   productImages: [{            ← additional images array
///     imageId: int,
///     productId: int,
///     imageUrl: string,
///     semanticLabel: string?,
///     isMain: bool
///   }],
///   brand: {brandId, name},
///   seller: {sellerId, storeName, userId, description, contactNumber},
///   subCategory: {
///     subCategoryId, name, categoryId,
///     category: {categoryId, name}
///   },
///   specifications: [{id, label, value, productId}],
///   productVariants: [{variantId, productId, colorId, sizeId, stock, priceAdjustment, color, size}],
///   productReviews: [{reviewId, productId, userId, rating, comment, createdAt}],
///   createdAt: datetime,
///   updatedAt: datetime
/// }
class Product {
  final int productId;
  final String name;
  final String description;
  final double price;
  final bool inStock;
  final int stock;
  final bool isApproved;
  final int? sellerId;
  final int? subCategoryId;
  final int? brandId;
  final String imageUrl;
  final List<String> imageUrls;
  final Map<String, dynamic>? brand;
  final Map<String, dynamic>? seller;
  final List<Map<String, dynamic>> specifications;
  final List<Map<String, dynamic>> productVariants;
  final List<Map<String, dynamic>> productReviews;
  final double rating;
  final int reviewsCount;
  final double originalPrice;

  final String? categoryName;
  final String? subCategoryName;
  final String? brandName;
  final String? sellerName;

  /// Cached normalized values for performance optimization (filtering/search)
  final String normalizedName;
  final String compactName;
  final String normalizedCategory;
  final String normalizedSubCategory;
  final String normalizedBrand;

  const Product({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.inStock,
    required this.imageUrl,
    required this.imageUrls,
    required this.specifications,
    required this.productVariants,
    required this.productReviews,
    this.originalPrice = 0.0,
    this.stock = 0,
    this.isApproved = true,
    this.sellerId,
    this.subCategoryId,
    this.brandId,
    this.brand,
    this.seller,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.categoryName,
    this.subCategoryName,
    this.brandName,
    this.sellerName,
    this.normalizedName = '',
    this.compactName = '',
    this.normalizedCategory = '',
    this.normalizedSubCategory = '',
    this.normalizedBrand = '',
  });

  /// Utility for string normalization to avoid repeated regex in build methods
  static String normalize(String? s) {
    if (s == null || s.isEmpty) return '';
    return s.toLowerCase().trim().replaceAll(',', '').replaceAll(RegExp(r'\s+'), ' ');
  }

  static String compact(String s) => s.replaceAll(' ', '');

  /// Ensures relative paths become full URLs using the centralized AuthService base.
  /// Handles spaces, backslashes, and HTTP→HTTPS upgrade for the API domain.
  static String _normalizeUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final t = url.trim().replaceAll('\\', '/');
    String finalUrl;

    if (t.startsWith('http://') || t.startsWith('https://')) {
      // Upgrade HTTP to HTTPS for our domain
      if (t.startsWith('http://egzone.runasp.net')) {
        finalUrl = t.replaceFirst('http://', 'https://');
      } else {
        finalUrl = t;
      }
      // Encode path segments
      try {
        final uri = Uri.parse(finalUrl);
        if (uri.host.contains('egzone.runasp.net')) {
          final encodedPath = uri.pathSegments.map((s) {
            try {
              return Uri.encodeComponent(Uri.decodeComponent(s));
            } catch (_) {
              return Uri.encodeComponent(s);
            }
          }).join('/');
          finalUrl = uri.replace(path: '/$encodedPath').toString();
        }
      } catch (_) {
        finalUrl = finalUrl.replaceAll(' ', '%20');
      }
    } else {
      // Relative path — build absolute URL
      final cleanPath = t.startsWith('/') ? t.substring(1) : t;
      final encoded = cleanPath
          .split('/')
          .map((seg) {
            try {
              return Uri.encodeComponent(Uri.decodeComponent(seg));
            } catch (_) {
              return Uri.encodeComponent(seg);
            }
          })
          .join('/');
      finalUrl = '${AuthService.baseUrl}/$encoded';
    }

    finalUrl = finalUrl.replaceAll(' ', '%20');

    // Web CORS Proxy Fix
    if (kIsWeb) {
      return 'https://corsproxy.io/?${Uri.encodeComponent(finalUrl)}';
    }

    return finalUrl;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // ── Images ──────────────────────────────────────────────────────────────
    // API returns productImages: [{imageId, productId, imageUrl, semanticLabel, isMain}]
    // or imageUrl as a flat string
    List<String> imageUrls = [];

    // Check productImages array first (detail endpoint)
    final productImagesRaw = json['productImages'] ?? json['ProductImages'];
    if (productImagesRaw is List && productImagesRaw.isNotEmpty) {
      // Sort: isMain first, then by imageId
      final sorted = List<dynamic>.from(productImagesRaw);
      sorted.sort((a, b) {
        final aMain = (a is Map && a['isMain'] == true) ? 0 : 1;
        final bMain = (b is Map && b['isMain'] == true) ? 0 : 1;
        return aMain.compareTo(bMain);
      });
      imageUrls = sorted
          .map((img) {
            if (img is String) return _normalizeUrl(img);
            if (img is Map) {
              return _normalizeUrl(
                img['imageUrl'] as String? ??
                img['ImageUrl'] as String? ??
                img['url'] as String?,
              );
            }
            return '';
          })
          .where((u) => u.isNotEmpty)
          .toList();
    }

    // Fallback: check 'images' array (legacy / custom format)
    if (imageUrls.isEmpty) {
      final imagesRaw = json['images'] ?? json['Images'];
      if (imagesRaw is List && imagesRaw.isNotEmpty) {
        imageUrls = imagesRaw
            .map((img) {
              if (img is String) return _normalizeUrl(img);
              if (img is Map) {
                return _normalizeUrl(
                  img['url'] as String? ??
                  img['imageUrl'] as String? ??
                  img['ImageUrl'] as String?,
                );
              }
              return '';
            })
            .where((u) => u.isNotEmpty)
            .toList();
      }
    }

    // Primary image URL
    final mainUrl = imageUrls.isNotEmpty
        ? imageUrls.first
        : _normalizeUrl(
            json['imageUrl'] as String? ?? json['ImageUrl'] as String?,
          );

    // ── Category / Subcategory ───────────────────────────────────────────────
    // The product schema includes:
    //   subCategory: {subCategoryId, name, categoryId, category: {categoryId, name}}
    String? categoryName;
    String? subCategoryName;

    // Check flat string fields first (custom API format)
    if (json['category'] is String) categoryName = json['category'] as String;
    if (json['subcategory'] is String) subCategoryName = json['subcategory'] as String;

    // Check nested subCategory object (standard swagger schema)
    if (categoryName == null || subCategoryName == null) {
      try {
        final subCatObj = (json['subCategory'] ??
                json['SubCategory'] ??
                json['subcategory']) as Map<String, dynamic>?;
        if (subCatObj != null) {
          subCategoryName ??= subCatObj['name'] as String?;
          // category nested inside subCategory
          final catObj = (subCatObj['category'] ?? subCatObj['Category'])
              as Map<String, dynamic>?;
          if (catObj != null) {
            categoryName ??= catObj['name'] as String?;
          }
        }
      } catch (_) {}
    }

    // ── Brand ────────────────────────────────────────────────────────────────
    // API schema: brand: {brandId: int, name: string}
    String? brandName;
    Map<String, dynamic>? brandMap;
    final rawBrand = json['brand'] ?? json['Brand'];
    if (rawBrand is Map<String, dynamic>) {
      brandMap = rawBrand;
      brandName = rawBrand['name'] as String?;
    } else if (rawBrand is String && rawBrand.isNotEmpty) {
      brandName = rawBrand;
    }

    // ── Seller ───────────────────────────────────────────────────────────────
    // API schema: seller: {sellerId, storeName, userId, description, contactNumber}
    String? sellerName;
    Map<String, dynamic>? sellerMap;
    final rawSeller = json['seller'] ?? json['Seller'];
    if (rawSeller is Map<String, dynamic>) {
      sellerMap = rawSeller;
      sellerName = (rawSeller['storeName'] ??
              rawSeller['name'] ??
              rawSeller['firstName']) as String?;
    } else if (rawSeller is String && rawSeller.isNotEmpty) {
      sellerName = rawSeller;
    }
    sellerName ??= (json['sellerName'] ?? json['SellerName']) as String?;

    // ── Stock / inStock ─────────────────────────────────────────────────────
    final stockInt = (json['stock'] as num?)?.toInt() ??
        (json['Stock'] as num?)?.toInt() ?? 0;
    final inStockBool = json['inStock'] as bool? ??
        json['InStock'] as bool? ??
        stockInt > 0;

    // ── Reviews ──────────────────────────────────────────────────────────────
    // API schema: productReviews: [{reviewId, rating, comment, createdAt, ...}]
    final reviewsRaw = json['productReviews'] ?? json['ProductReviews'] ?? json['reviews'];
    final List<Map<String, dynamic>> reviews = _safeMapList(reviewsRaw);

    // Calculate average rating from reviews if not directly provided
    double ratingVal = (json['rating'] as num?)?.toDouble() ?? 0.0;
    int reviewsCount = (json['reviewsCount'] as num?)?.toInt() ?? reviews.length;
    if (ratingVal == 0.0 && reviews.isNotEmpty) {
      final totalRating = reviews.fold<double>(
        0.0,
        (sum, r) => sum + ((r['rating'] as num?)?.toDouble() ?? 0.0),
      );
      ratingVal = totalRating / reviews.length;
      reviewsCount = reviews.length;
    }

    final name = json['name'] as String? ?? json['Name'] as String? ?? '';
    final normName = normalize(name);

    return Product(
      productId: (json['productId'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          (json['ProductId'] as num?)?.toInt() ?? 0,
      name: name,
      description: json['description'] as String? ?? json['Description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
      inStock: inStockBool,
      stock: stockInt,
      isApproved: json['isApproved'] as bool? ?? true,
      sellerId: (json['sellerId'] as num?)?.toInt(),
      subCategoryId: (json['subCategoryId'] as num?)?.toInt(),
      brandId: (json['brandId'] as num?)?.toInt(),
      imageUrl: mainUrl,
      imageUrls: imageUrls,
      brand: brandMap,
      seller: sellerMap,
      specifications: _safeMapList(
          json['specifications'] ?? json['Specifications']),
      productVariants: _safeMapList(
          json['productVariants'] ?? json['ProductVariants']),
      productReviews: reviews,
      rating: ratingVal,
      reviewsCount: reviewsCount,
      categoryName: categoryName,
      subCategoryName: subCategoryName,
      brandName: brandName,
      sellerName: sellerName,
      normalizedName: normName,
      compactName: compact(normName),
      normalizedCategory: normalize(categoryName),
      normalizedSubCategory: normalize(subCategoryName),
      normalizedBrand: normalize(brandName),
    );
  }

  static List<Map<String, dynamic>> _safeMapList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .where((m) => m.isNotEmpty)
          .toList();
    } else if (data is Map) {
      return [Map<String, dynamic>.from(data)];
    }
    return [];
  }

  /// Convert to the legacy Map format used by ProductDetailScreen & CartProvider
  Map<String, dynamic> toMap() {
    final List<String> effectiveUrls = imageUrls.isNotEmpty
        ? imageUrls
        : (imageUrl.isNotEmpty ? [imageUrl] : []);

    return {
      'id': productId,
      'productId': productId,
      'name': name,
      'price': price,
      'originalPrice': originalPrice,
      'imageUrl': imageUrl,
      'description': description,
      'category': categoryName,
      'subcategory': subCategoryName,
      'subCategoryId': subCategoryId,
      'subCategoryName': subCategoryName,
      'categoryName': categoryName,
      'brandName': brandName,
      'sellerName': sellerName,
      'stock': stock,
      'inStock': inStock,
      'isApproved': isApproved,
      'sellerId': sellerId,
      'brandId': brandId,
      'brand': brand,
      'seller': seller,
      'rating': rating,
      'reviewsCount': reviewsCount,
      // Use productImages format so detail screen can render them
      'images': effectiveUrls
          .map((url) => {'url': url, 'imageUrl': url, 'semanticLabel': name})
          .toList(),
      'productImages': effectiveUrls
          .asMap()
          .entries
          .map((e) => {
                'imageId': e.key,
                'imageUrl': e.value,
                'semanticLabel': name,
                'isMain': e.key == 0,
              })
          .toList(),
      'specifications': specifications,
      'productVariants': productVariants,
      'productReviews': productReviews,
    };
  }
}
