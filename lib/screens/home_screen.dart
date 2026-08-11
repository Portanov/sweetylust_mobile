import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../providers/providers.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 12;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productNotifierProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    final productState = ref.read(productNotifierProvider);
    final totalProducts = productState.totalProducts;
    final currentProducts = productState.products.length;

    if (currentProducts >= totalProducts) {
      setState(() => _hasMore = false);
      return;
    }

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    final notifier = ref.read(productNotifierProvider.notifier);
    await notifier.loadMore(_currentPage, _pageSize);

    setState(() {
      _isLoadingMore = false;
      _hasMore = currentProducts < totalProducts;
    });
  }

  Future<void> _addToCart(Product product) async {
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    final success = await cartNotifier.addToCart(product.id, 1);

    if (success && mounted) {
      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.success,
        title: Text('Éxito'),
        description: RichText(text: TextSpan(text: 'Producto agregado al carrito correctamente')),
        autoCloseDuration: const Duration(seconds: 3),
        dragToClose: true,
      );
    } else if (mounted) {
      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.error,
        title: Text('Éxito'),
        description: RichText(
          text: TextSpan(text: 'Error al agregar ${product.title}'),
        ),
        autoCloseDuration: const Duration(seconds: 3),
        dragToClose: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productNotifierProvider);
    final products = productState.products;
    final categories = ref.watch(categoriesWithAllProvider);
    final hasFilters = ref.watch(hasActiveFiltersProvider);
    final isLoading = productState.isLoading && products.isEmpty;

    ref.listen(productNotifierProvider, (previous, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(productNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SearchBar(
              controller: _searchController,
              hintText: 'Buscar productos...',
              leading: const Icon(Icons.search),
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 14.0),
              ),
              backgroundColor: WidgetStatePropertyAll<Color>(Colors.grey[200]!),
              elevation: const WidgetStatePropertyAll<double>(0.0),
              onChanged: (value) {
                setState(() {
                  _currentPage = 0;
                  _hasMore = true;
                });
                ref.read(productNotifierProvider.notifier).search(value ?? '');
              },
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _currentPage = 0;
                        _hasMore = true;
                      });
                      ref.read(productNotifierProvider.notifier).search('');
                    },
                  ),
              ],
            ),

            const SizedBox(height: 16),

            if (categories.isNotEmpty)
              _buildCategoryFilters(categories, productState.selectedCategory),

            const SizedBox(height: 12),

            if (!isLoading) _buildAdditionalFilters(productState, hasFilters),

            const SizedBox(height: 16),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildProductGrid(productState, products, hasFilters),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(
    List<CategoryWithCount> categories,
    ProductCategory? selectedCategory,
  ) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isAll = index == 0;
          final isSelected = isAll
              ? selectedCategory == null
              : selectedCategory == category.category;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                isAll ? 'Todas' : category.category.displayName,
                style: GoogleFonts.alumniSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.0,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFFE38888),
              labelStyle: GoogleFonts.alumniSans(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.0,
                color: isSelected ? Colors.white : Colors.black,
              ),
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _currentPage = 0;
                    _hasMore = true;
                  });
                  if (isAll) {
                    ref
                        .read(productNotifierProvider.notifier)
                        .selectCategory(null);
                  } else {
                    ref
                        .read(productNotifierProvider.notifier)
                        .selectCategory(category.category);
                  }
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              side: BorderSide.none,
              backgroundColor: const Color(0xFFFFD5D5),
              checkmarkColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdditionalFilters(ProductState state, bool hasFilters) {
    return Row(
      children: [
        FilterChip(
          label: const Text('Ofertas'),
          selected: state.onSaleOnly,
          onSelected: (_) {
            setState(() {
              _currentPage = 0;
              _hasMore = true;
            });
            ref.read(productNotifierProvider.notifier).toggleOnSale();
          },
          backgroundColor: Colors.grey[200],
          selectedColor: const Color(0xFFFFD5D5),
          labelStyle: TextStyle(
            color: state.onSaleOnly ? Colors.black : Colors.grey[700],
            fontWeight: state.onSaleOnly ? FontWeight.w600 : FontWeight.normal,
          ),
          avatar: Icon(
            Icons.local_offer,
            size: 18,
            color: state.onSaleOnly ? Colors.red : Colors.grey,
          ),
        ),
        const SizedBox(width: 8),

        FilterChip(
          label: const Text('En stock'),
          selected: state.inStockOnly,
          onSelected: (_) {
            setState(() {
              _currentPage = 0;
              _hasMore = true;
            });
            ref.read(productNotifierProvider.notifier).toggleInStock();
          },
          backgroundColor: Colors.grey[200],
          selectedColor: const Color(0xFFFFD5D5),
          labelStyle: TextStyle(
            color: state.inStockOnly ? Colors.black : Colors.grey[700],
            fontWeight: state.inStockOnly ? FontWeight.w600 : FontWeight.normal,
          ),
          avatar: Icon(
            Icons.inventory_2,
            size: 18,
            color: state.inStockOnly ? Colors.green : Colors.grey,
          ),
        ),
        const Spacer(),

        Text(
          '${state.totalProducts} productos',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProductGrid(
    ProductState state,
    List<Product> products,
    bool hasFilters,
  ) {
    if (products.isEmpty && !state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No se encontraron productos con estos filtros'
                  : 'No hay productos disponibles',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentPage = 0;
                    _hasMore = true;
                  });
                  ref.read(productNotifierProvider.notifier).resetFilters();
                  _searchController.clear();
                },
                child: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == products.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final product = products[index];
        return ProductCard(
          product: product,
          onAddToCart: () {
            _addToCart(product);
          },
        );
      },
    );
  }
}
