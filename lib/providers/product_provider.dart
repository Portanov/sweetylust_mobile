import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import 'service_providers.dart';

class ProductState {
  final List<Product> products;
  final List<CategoryWithCount> categories;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final String searchTerm;
  final ProductCategory? selectedCategory;
  final double? minPrice;
  final double? maxPrice;
  final bool onSaleOnly;
  final bool inStockOnly;
  final int currentPage;
  final int totalProducts;
  final int pageSize;
  final double maxPossiblePrice;

  ProductState({
    this.products = const [],
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.searchTerm = '',
    this.selectedCategory,
    this.minPrice,
    this.maxPrice,
    this.onSaleOnly = false,
    this.inStockOnly = false,
    this.currentPage = 0,
    this.totalProducts = 0,
    this.pageSize = 12,
    this.maxPossiblePrice = 10000,
  });

  List<Product> get pagedProducts {
    final start = currentPage * pageSize;
    final end = (start + pageSize).clamp(0, products.length);
    return products.sublist(start, end);
  }

  List<CategoryWithCount> get categoriesWithAll {
    final total = categories.fold<int>(0, (sum, c) => sum + c.count);
    return [
      CategoryWithCount(category: ProductCategory.otros, count: total),
      ...categories,
    ];
  }

  bool get hasActiveFilters {
    return searchTerm.isNotEmpty ||
        selectedCategory != null ||
        minPrice != null ||
        maxPrice != null ||
        onSaleOnly ||
        inStockOnly;
  }

  ProductState copyWith({
    List<Product>? products,
    List<CategoryWithCount>? categories,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    String? searchTerm,
    ProductCategory? selectedCategory,
    double? minPrice,
    double? maxPrice,
    bool? onSaleOnly,
    bool? inStockOnly,
    int? currentPage,
    int? totalProducts,
    int? pageSize,
    double? maxPossiblePrice,
  }) {
    return ProductState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
      searchTerm: searchTerm ?? this.searchTerm,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      onSaleOnly: onSaleOnly ?? this.onSaleOnly,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      currentPage: currentPage ?? this.currentPage,
      totalProducts: totalProducts ?? this.totalProducts,
      pageSize: pageSize ?? this.pageSize,
      maxPossiblePrice: maxPossiblePrice ?? this.maxPossiblePrice,
    );
  }

  factory ProductState.initial() => ProductState();
  factory ProductState.loading() => ProductState(isLoading: true);
  factory ProductState.error(String message) => ProductState(error: message);
}

class ProductNotifier extends StateNotifier<ProductState> {
  final ProductService _service;
  bool _isLoadingProducts = false;
  bool _initialized = false;

  ProductNotifier(this._service) : super(ProductState.initial());

  Future<void> initialize() async {
    if (_initialized) return;

    state = state.copyWith(isLoading: true);

    try {
      final results = await Future.wait([
        _service.getCategories(),
        _service.getProducts(),
      ]);

      final categories = results[0] as List<CategoryWithCount>;
      final productResponse = results[1] as ProductResponse;

      final maxP = productResponse.products.isEmpty
          ? 1000.0
          : productResponse.products
                .map((p) => p.price)
                .reduce((a, b) => a > b ? a : b);
      final rounded = (maxP / 100).ceil() * 100;

      state = ProductState(
        products: productResponse.products,
        categories: categories,
        totalProducts: productResponse.total,
        maxPossiblePrice: rounded.toDouble(),
        isInitialized: true,
        isLoading: false,
      );

      _initialized = true;
    } catch (e) {
      state = ProductState.error(e.toString());
      _initialized = true;
    }
  }

  Future<void> loadProducts() async {
    if (_isLoadingProducts) return;
    _isLoadingProducts = true;

    state = state.copyWith(isLoading: true);

    try {
      final filters = _buildFilters();
      final response = await _service.getProducts(filters);

      state = state.copyWith(
        products: response.products,
        totalProducts: response.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        products: [],
        totalProducts: 0,
        isLoading: false,
        error: e.toString(),
      );
    } finally {
      _isLoadingProducts = false;
    }
  }

  Future<void> loadMore(int page, int pageSize) async {
    if (_isLoadingProducts) return;
    _isLoadingProducts = true;

    try {
      final filters = _buildFilters();
      final response = await _service.getProducts(filters);
      final allProducts = [...state.products, ...response.products];

      state = state.copyWith(
        products: allProducts,
        totalProducts: response.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      _isLoadingProducts = false;
    }
  }

  ProductFilters? _buildFilters() {
    final filters = <String, dynamic>{};

    if (state.searchTerm.isNotEmpty) {
      filters['search'] = state.searchTerm;
    }
    if (state.selectedCategory != null) {
      filters['category'] = state.selectedCategory.toString().split('.').last;
    }
    if (state.minPrice != null) {
      filters['minPrice'] = state.minPrice;
    }
    if (state.maxPrice != null) {
      filters['maxPrice'] = state.maxPrice;
    }
    if (state.onSaleOnly) {
      filters['onSale'] = true;
    }
    if (state.inStockOnly) {
      filters['inStock'] = true;
    }

    if (filters.isEmpty) return null;

    return ProductFilters(
      search: filters['search'] as String?,
      category: state.selectedCategory,
      minPrice: state.minPrice,
      maxPrice: state.maxPrice,
      onSale: state.onSaleOnly,
      inStock: state.inStockOnly,
    );
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void search(String term) {
    state = state.copyWith(searchTerm: term, products: [], currentPage: 0);
    loadProducts();
  }

  void selectCategory(ProductCategory? category) {
    state = state.copyWith(
      selectedCategory: category,
      products: [],
      currentPage: 0,
    );
    loadProducts();
  }

  void toggleOnSale() {
    state = state.copyWith(
      onSaleOnly: !state.onSaleOnly,
      products: [],
      currentPage: 0,
    );
    loadProducts();
  }

  void toggleInStock() {
    state = state.copyWith(
      inStockOnly: !state.inStockOnly,
      products: [],
      currentPage: 0,
    );
    loadProducts();
  }

  void resetFilters() {
    state = ProductState(
      categories: state.categories,
      maxPossiblePrice: state.maxPossiblePrice,
      isInitialized: true,
      isLoading: false,
    );
    _initialized = true;
    loadProducts();
  }

  void setPriceRange(double min, double max) {
    state = state.copyWith(minPrice: min, maxPrice: max, currentPage: 0);
    loadProducts();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, ProductState>((ref) {
      final service = ref.watch(productServiceProvider);
      return ProductNotifier(service);
    });

final pagedProductsProvider = Provider<List<Product>>((ref) {
  return ref.watch(productNotifierProvider).pagedProducts;
});

final categoriesWithAllProvider = Provider<List<CategoryWithCount>>((ref) {
  return ref.watch(productNotifierProvider).categoriesWithAll;
});

final hasActiveFiltersProvider = Provider<bool>((ref) {
  return ref.watch(productNotifierProvider).hasActiveFilters;
});

final totalProductsProvider = Provider<int>((ref) {
  return ref.watch(productNotifierProvider).totalProducts;
});

final maxPossiblePriceProvider = Provider<double>((ref) {
  return ref.watch(productNotifierProvider).maxPossiblePrice;
});
