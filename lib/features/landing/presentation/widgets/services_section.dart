import 'package:flutter/material.dart';

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEEF7FB),
      padding: const EdgeInsets.fromLTRB(
        20,
        34,
        20,
        40,
      ),
      child: Column(
        children: [
          const Text(
            'Our Service',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF161B20),
            ),
          ),

          const SizedBox(height: 26),

          // Service cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
            childAspectRatio: 1.05,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              ServiceCard(
                icon: Icons.inventory_2_outlined,
                title: 'Inventory Control',
                description:
                    'Smart stock management with low-stock alerts and real-time inventory updates.',
              ),

              ServiceCard(
                icon: Icons.analytics_outlined,
                title: 'Real-time Analytics',
                description:
                    'Live dashboards with sales metrics, top products, and customizable reports to track your business performance.',
              ),

              ServiceCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Debt Management',
                description:
                    'Track customer debt, payment schedules, and automated reminders for outstanding balances.',
              ),

              ServiceCard(
                icon: Icons.point_of_sale_outlined,
                title: 'Sales',
                description:
                    'Easy point-of-sale system to record transactions and track history.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: 17,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 9),

          // Title
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF161B20),
            ),
          ),

          const SizedBox(height: 5),

          // Description
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 9,
                height: 1.3,
                fontWeight: FontWeight.w400,
                color: Color.fromARGB(255, 80, 102, 126),
                
              ),
            ),
          ),
        ],
      ),
    );
  }
}