import 'package:flutter/material.dart';

class ShopNeedsSection extends StatelessWidget {
  const ShopNeedsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 38,
      ),
      child: Column(
        children: [
          const Text(
            'Everything Your Shop Needs',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF161B20),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'From simple sales transactions to complex inventory management, '
            'Andalus provides all the tools to run your business efficiently.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              height: 1.4,
              fontWeight: FontWeight.w400,
              color: Color.fromARGB(255, 80, 102, 126),
            ),
          ),
        ],
      ),
    );
  }
}