import 'package:json_annotation/json_annotation.dart';
part 'product_model.g.dart';

double _parsePrice(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
  return 0.0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(cleaned) ?? 0;
  }
  return 0;
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

String _parseString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

bool _parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  if (value is num) {
    return value != 0;
  }
  return false;
}

enum OfferType {
  @JsonValue('percentage')
  percentage,
  @JsonValue('fixed_price')
  fixedPrice,
  @JsonValue('two_for_one')
  twoForOne,
  @JsonValue('bundle')
  bundle,
}

enum ProductCategory {
  @JsonValue('disfraces')
  disfraces,
  @JsonValue('vibradores')
  vibradores,
  @JsonValue('juguetes')
  juguetes,
  @JsonValue('lenceria')
  lenceria,
  @JsonValue('accesorios')
  accesorios,
  @JsonValue('lubricantes')
  lubricantes,
  @JsonValue('condones')
  condones,
  @JsonValue('juegos')
  juegos,
  @JsonValue('aceites')
  aceites,
  @JsonValue('bondage')
  bondage,
  @JsonValue('mascaras')
  mascaras,
  @JsonValue('muñecas')
  munecas,
  @JsonValue('otros')
  otros,
}

extension ProductCategoryExtension on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.disfraces:
        return 'Disfraces';
      case ProductCategory.vibradores:
        return 'Vibradores';
      case ProductCategory.juguetes:
        return 'Juguetes';
      case ProductCategory.lenceria:
        return 'Lencería';
      case ProductCategory.accesorios:
        return 'Accesorios';
      case ProductCategory.lubricantes:
        return 'Lubricantes';
      case ProductCategory.condones:
        return 'Condones';
      case ProductCategory.juegos:
        return 'Juegos';
      case ProductCategory.aceites:
        return 'Aceites';
      case ProductCategory.bondage:
        return 'Bondage';
      case ProductCategory.mascaras:
        return 'Máscaras';
      case ProductCategory.munecas:
        return 'Muñecas';
      case ProductCategory.otros:
        return 'Otros';
    }
  }

  static ProductCategory fromString(String value) {
    final normalized = value.toLowerCase().trim();
    switch (normalized) {
      case 'disfraces':
      case 'disfraz':
        return ProductCategory.disfraces;
      case 'vibradores':
      case 'vibrador':
        return ProductCategory.vibradores;
      case 'juguetes':
      case 'juguete':
        return ProductCategory.juguetes;
      case 'lenceria':
      case 'lencería':
        return ProductCategory.lenceria;
      case 'accesorios':
      case 'accesorio':
        return ProductCategory.accesorios;
      case 'lubricantes':
      case 'lubricante':
        return ProductCategory.lubricantes;
      case 'condones':
      case 'condon':
        return ProductCategory.condones;
      case 'juegos':
      case 'juego':
        return ProductCategory.juegos;
      case 'aceites':
      case 'aceite':
        return ProductCategory.aceites;
      case 'bondage':
        return ProductCategory.bondage;
      case 'mascaras':
      case 'mascara':
        return ProductCategory.mascaras;
      case 'muñecas':
      case 'munecas':
      case 'muñeca':
      case 'muneca':
        return ProductCategory.munecas;
      default:
        return ProductCategory.otros;
    }
  }
}

@JsonSerializable()
class Offer {
  final int id;
  final int productId;
  final OfferType type;
  final String label;
  final double? discountValue;
  final int? bundleQuantity;
  final bool? isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Offer({
    required this.id,
    required this.productId,
    required this.type,
    required this.label,
    this.discountValue,
    this.bundleQuantity,
    this.isActive,
    this.startsAt,
    this.endsAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: _parseInt(json['id']),
      productId: _parseInt(json['productId'] ?? json['product_id']),
      type: _parseOfferType(json['type']),
      label: _parseString(json['label']),
      discountValue: _parsePrice(
        json['discountValue'] ?? json['discount_value'],
      ),
      bundleQuantity: _parseInt(
        json['bundleQuantity'] ?? json['bundle_quantity'],
      ),
      isActive: _parseBool(json['isActive'] ?? json['is_active']),
      startsAt: json['startsAt'] != null
          ? DateTime.tryParse(_parseString(json['startsAt']))
          : null,
      endsAt: json['endsAt'] != null
          ? DateTime.tryParse(_parseString(json['endsAt']))
          : null,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  static OfferType _parseOfferType(dynamic value) {
    if (value == null) return OfferType.percentage;
    if (value is OfferType) return value;
    final str = _parseString(value).toLowerCase();
    switch (str) {
      case 'percentage':
      case 'porcentaje':
        return OfferType.percentage;
      case 'fixed_price':
      case 'precio_fijo':
        return OfferType.fixedPrice;
      case 'two_for_one':
      case '2x1':
        return OfferType.twoForOne;
      case 'bundle':
      case 'paquete':
        return OfferType.bundle;
      default:
        return OfferType.percentage;
    }
  }

  Map<String, dynamic> toJson() => _$OfferToJson(this);
}

@JsonSerializable()
class Product {
  final int id;
  final String title;
  final String description;
  final String image;
  final double price;
  final int stock;
  final ProductCategory? category;
  final Offer? offer;
  final double? finalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.price,
    required this.stock,
    this.category,
    this.offer,
    this.finalPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    ProductCategory? category;
    final categoryValue = json['category'];
    if (categoryValue != null) {
      try {
        if (categoryValue is String) {
          category = ProductCategoryExtension.fromString(categoryValue);
        } else if (categoryValue is Map) {
          final categoryName = _parseString(
            categoryValue['name'] ?? categoryValue['category'],
          );
          if (categoryName.isNotEmpty) {
            category = ProductCategoryExtension.fromString(categoryName);
          }
        }
      } catch (_) {
        category = null;
      }
    }

    Offer? offer;
    final offerData = json['offer'];
    if (offerData != null && offerData is Map && offerData.isNotEmpty) {
      try {
        final convertedMap = Map<String, dynamic>.from(offerData);
        offer = Offer.fromJson(convertedMap);
      } catch (_) {
        offer = null;
      }
    }

    double? finalPrice;
    if (offer != null) {
      final price = _parsePrice(json['price']);
      if (offer.type == OfferType.percentage && offer.discountValue != null) {
        finalPrice = price * (1 - offer.discountValue! / 100);
      } else if (offer.type == OfferType.fixedPrice &&
          offer.discountValue != null) {
        finalPrice = offer.discountValue;
      } else if (offer.type == OfferType.twoForOne) {
        finalPrice = price / 2;
      } else if (offer.type == OfferType.bundle &&
          offer.bundleQuantity != null) {
        final price = _parsePrice(json['price']);
        finalPrice = price;
      }
    }

    return Product(
      id: _parseInt(json['id']),
      title: _parseString(json['title']),
      description: _parseString(json['description']),
      image: _parseString(json['image']),
      price: _parsePrice(json['price']),
      stock: _parseInt(json['stock']),
      category: category,
      offer: offer,
      finalPrice: finalPrice,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => _$ProductToJson(this);
}

@JsonSerializable()
class CategoryWithCount {
  final ProductCategory category;
  final int count;

  CategoryWithCount({required this.category, required this.count});

  factory CategoryWithCount.fromJson(Map<String, dynamic> json) {
    ProductCategory category;
    final categoryValue = json['category'];

    if (categoryValue is String) {
      category = ProductCategoryExtension.fromString(categoryValue);
    } else if (categoryValue is Map) {
      final categoryName = _parseString(
        categoryValue['name'] ??
            categoryValue['category'] ??
            categoryValue['_id'],
      );
      category = categoryName.isNotEmpty
          ? ProductCategoryExtension.fromString(categoryName)
          : ProductCategory.otros;
    } else {
      category = ProductCategory.otros;
    }

    return CategoryWithCount(
      category: category,
      count: _parseInt(json['count']),
    );
  }

  Map<String, dynamic> toJson() => _$CategoryWithCountToJson(this);
}

@JsonSerializable()
class ProductResponse {
  final List<Product> products;
  final int total;

  ProductResponse({required this.products, required this.total});

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    List<Product> products = [];

    final productsData = json['products'] ?? json['data'] ?? json;

    if (productsData is List) {
      products = productsData
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (productsData is Map) {
      final list = productsData['products'] ?? productsData['data'] ?? [];
      if (list is List) {
        products = list
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    return ProductResponse(
      products: products,
      total: _parseInt(json['total'] ?? products.length),
    );
  }

  Map<String, dynamic> toJson() => _$ProductResponseToJson(this);
}

@JsonSerializable()
class ProductFilters {
  final String? search;
  final ProductCategory? category;
  final double? minPrice;
  final double? maxPrice;
  final bool? onSale;
  final bool? inStock;

  ProductFilters({
    this.search,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.onSale,
    this.inStock,
  });

  factory ProductFilters.fromJson(Map<String, dynamic> json) =>
      _$ProductFiltersFromJson(json);
  Map<String, dynamic> toJson() => _$ProductFiltersToJson(this);
}
