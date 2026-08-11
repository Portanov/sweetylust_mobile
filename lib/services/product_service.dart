import '../models/product_model.dart';
import 'base_service.dart';

class ProductService extends BaseService {
  ProductService({required super.httpClient, required super.apiUrl});

  @override
  String get basePath => '/products';

  Future<ProductResponse> getProducts([ProductFilters? filters]) {
    final queryParams = <String, String>{};

    if (filters != null) {
      if (filters.search != null && filters.search!.isNotEmpty) {
        queryParams['search'] = filters.search!;
      }
      if (filters.category != null) {
        queryParams['category'] = filters.category.toString().split('.').last;
      }
      if (filters.minPrice != null) {
        queryParams['minPrice'] = filters.minPrice.toString();
      }
      if (filters.maxPrice != null) {
        queryParams['maxPrice'] = filters.maxPrice.toString();
      }
      if (filters.onSale != null) {
        queryParams['onSale'] = filters.onSale.toString();
      }
      if (filters.inStock != null) {
        queryParams['inStock'] = filters.inStock.toString();
      }
    }

    return get<ProductResponse>(
      '',
      fromJson: (json) => ProductResponse.fromJson(json),
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  Future<List<CategoryWithCount>> getCategories() {
    return getList<CategoryWithCount>(
      '/categories',
      fromJson: (json) => CategoryWithCount.fromJson(json),
    );
  }

  Future<Product> getProductById(int id) {
    return get<Product>('/$id', fromJson: (json) => Product.fromJson(json));
  }

  Future<List<Product>> getProductsOnSale() {
    return getList<Product>(
      '/on-sale',
      fromJson: (json) => Product.fromJson(json),
    );
  }
}
