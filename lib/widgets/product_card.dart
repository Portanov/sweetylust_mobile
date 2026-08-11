import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onAddToCart;

  const ProductCard({super.key, required this.product, this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final hasValidOffer = product.offer != null;
    final hasDiscount =
        hasValidOffer &&
        product.finalPrice != null &&
        product.finalPrice! < product.price;

    final displayPrice = hasDiscount ? product.finalPrice! : product.price;
    final isOutOfStock = product.stock <= 0;

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 42) / 2;
    final cardHeight = cardWidth * 1.4;

    return SizedBox(
      height: cardHeight,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F5),
          borderRadius: BorderRadius.circular(16.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.image.isNotEmpty
                      ? Image.network(
                          product.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 30,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),

                  if (hasDiscount)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getOfferLabel(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  if (isOutOfStock)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Agotado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: GoogleFonts.poiretOne(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasDiscount) ...[
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),

                                Text(
                                  '\$${displayPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.alumniSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.red,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  '\$${displayPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.alumniSans(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        if (!isOutOfStock)
                          IconButton(
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              color: Color(0xFF344054),
                              size: 28,
                            ),
                            onPressed: onAddToCart,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getOfferLabel() {
    if (product.offer == null) return '';

    switch (product.offer!.type) {
      case OfferType.percentage:
        return '${product.offer!.discountValue?.toInt()}% OFF';
      case OfferType.fixedPrice:
        return 'Liquidación';
      case OfferType.twoForOne:
        return '2x1';
      case OfferType.bundle:
        return 'Pack';
      default:
        return product.offer!.label.isNotEmpty
            ? product.offer!.label
            : 'Oferta';
    }
  }
}
