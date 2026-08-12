import 'package:flutter/material.dart';
import '../widgets/landing_header.dart';
import '../widgets/hero_section.dart';
import '../widgets/shop_needs_section.dart';
import '../widgets/services_section.dart';
import '../widgets/footer_section.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const LandingHeader(),
              const HeroSection(),
              const ShopNeedsSection(),
              const ServicesSection(),
              const FooterSection(),
            ],
          ),
        ),
      ),
    );
  }
}