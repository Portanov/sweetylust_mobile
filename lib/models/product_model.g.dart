// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Offer _$OfferFromJson(Map<String, dynamic> json) => Offer(
  id: (json['id'] as num).toInt(),
  productId: (json['productId'] as num).toInt(),
  type: $enumDecode(_$OfferTypeEnumMap, json['type']),
  label: json['label'] as String,
  discountValue: (json['discountValue'] as num?)?.toDouble(),
  bundleQuantity: (json['bundleQuantity'] as num?)?.toInt(),
  isActive: json['isActive'] as bool?,
  startsAt: json['startsAt'] == null
      ? null
      : DateTime.parse(json['startsAt'] as String),
  endsAt: json['endsAt'] == null
      ? null
      : DateTime.parse(json['endsAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$OfferToJson(Offer instance) => <String, dynamic>{
  'id': instance.id,
  'productId': instance.productId,
  'type': _$OfferTypeEnumMap[instance.type]!,
  'label': instance.label,
  'discountValue': instance.discountValue,
  'bundleQuantity': instance.bundleQuantity,
  'isActive': instance.isActive,
  'startsAt': instance.startsAt?.toIso8601String(),
  'endsAt': instance.endsAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$OfferTypeEnumMap = {
  OfferType.percentage: 'percentage',
  OfferType.fixedPrice: 'fixed_price',
  OfferType.twoForOne: 'two_for_one',
  OfferType.bundle: 'bundle',
};

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  image: json['image'] as String,
  price: (json['price'] as num).toDouble(),
  stock: (json['stock'] as num).toInt(),
  category: $enumDecodeNullable(_$ProductCategoryEnumMap, json['category']),
  offer: json['offer'] == null
      ? null
      : Offer.fromJson(json['offer'] as Map<String, dynamic>),
  finalPrice: (json['finalPrice'] as num?)?.toDouble(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'image': instance.image,
  'price': instance.price,
  'stock': instance.stock,
  'category': _$ProductCategoryEnumMap[instance.category],
  'offer': instance.offer,
  'finalPrice': instance.finalPrice,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$ProductCategoryEnumMap = {
  ProductCategory.disfraces: 'disfraces',
  ProductCategory.vibradores: 'vibradores',
  ProductCategory.juguetes: 'juguetes',
  ProductCategory.lenceria: 'lenceria',
  ProductCategory.accesorios: 'accesorios',
  ProductCategory.lubricantes: 'lubricantes',
  ProductCategory.condones: 'condones',
  ProductCategory.juegos: 'juegos',
  ProductCategory.aceites: 'aceites',
  ProductCategory.bondage: 'bondage',
  ProductCategory.mascaras: 'mascaras',
  ProductCategory.munecas: 'muñecas',
  ProductCategory.otros: 'otros',
};

CategoryWithCount _$CategoryWithCountFromJson(Map<String, dynamic> json) =>
    CategoryWithCount(
      category: $enumDecode(_$ProductCategoryEnumMap, json['category']),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$CategoryWithCountToJson(CategoryWithCount instance) =>
    <String, dynamic>{
      'category': _$ProductCategoryEnumMap[instance.category]!,
      'count': instance.count,
    };

ProductResponse _$ProductResponseFromJson(Map<String, dynamic> json) =>
    ProductResponse(
      products: (json['products'] as List<dynamic>)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$ProductResponseToJson(ProductResponse instance) =>
    <String, dynamic>{'products': instance.products, 'total': instance.total};

ProductFilters _$ProductFiltersFromJson(Map<String, dynamic> json) =>
    ProductFilters(
      search: json['search'] as String?,
      category: $enumDecodeNullable(_$ProductCategoryEnumMap, json['category']),
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      onSale: json['onSale'] as bool?,
      inStock: json['inStock'] as bool?,
    );

Map<String, dynamic> _$ProductFiltersToJson(ProductFilters instance) =>
    <String, dynamic>{
      'search': instance.search,
      'category': _$ProductCategoryEnumMap[instance.category],
      'minPrice': instance.minPrice,
      'maxPrice': instance.maxPrice,
      'onSale': instance.onSale,
      'inStock': instance.inStock,
    };
