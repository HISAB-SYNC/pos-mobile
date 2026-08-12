import 'package:flutter/material.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEEF7FB),
      padding: const EdgeInsets.fromLTRB(
        20,
        28,
        20,
        35,
      ),
      child: Column(
        children: [
          // Heading + Dashboard
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Heading
              Expanded(
                flex: 5,
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Streamline\n',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          color: Color(0xFF161B20),
                        ),
                      ),

                      // "Your Shop" highlighted
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'Your Shop',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const TextSpan(
                        text: '\nManagement',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          color: Color(0xFF161B20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Dashboard image
              Expanded(
                flex: 5,
                child: Image.asset(
                  'assets/images/dashboard.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Description
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              'Designed for Mini-Markets, easy for anyone to use, '
              'and ready to grow with your business.',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w400,
                color: Color(0xFF61758A),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Get Started button
          Center(
            child: SizedBox(
              width: 130,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  // Login navigation will be added later.
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}