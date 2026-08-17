import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/cart_provider.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        title: const Text(
          'Cart',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF20252B),
          ),
        ),

        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              onPressed: () {
                cart.clearCart();
              },
              icon: const Icon(
                Icons.delete_outline,
                color: Color(0xFF64748B),
              ),
            ),
        ],
      ),

      body: cart.items.isEmpty
          ? const _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: cart.items.length,

                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),

                    itemBuilder: (context, index) {
                      final item = cart.items[index];

                      return _CartItemCard(
                        item: item,
                        onIncrease: () {
                          cart.addProduct(item.product);
                        },
                        onDecrease: () {
                          cart.decreaseProduct(item.product);
                        },
                        onRemove: () {
                          cart.removeProduct(item.product);
                        },
                      );
                    },
                  ),
                ),

                _CartSummary(
                  subtotal: cart.subtotal,
                  itemCount: cart.itemCount,
                ),
              ],
            ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 38,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF20252B),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Add products from the catalog',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20252B),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF20252B),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${item.product.price.toStringAsFixed(0)} ETB',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    _QuantityButton(
                      icon: Icons.remove,
                      onPressed: onDecrease,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    _QuantityButton(
                      icon: Icons.add,
                      onPressed: onIncrease,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              ),

              Text(
                '${item.total.toStringAsFixed(0)} ETB',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF20252B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),

      child: Container(
        width: 30,
        height: 30,

        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
          borderRadius: BorderRadius.circular(8),
        ),

        child: Icon(
          icon,
          size: 16,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final double subtotal;
  final int itemCount;

  const _CartSummary({
    required this.subtotal,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20,
      ),

      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),

      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items ($itemCount)',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),

              Text(
                '${subtotal.toStringAsFixed(0)} ETB',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              Text(
                '${subtotal.toStringAsFixed(0)} ETB',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 52,

            child: ElevatedButton(
            onPressed: () {
  Navigator.pushNamed(context, '/checkout');
},

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20252B),
                foregroundColor: Colors.white,
                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              child: const Text(
                'Continue to Checkout',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}