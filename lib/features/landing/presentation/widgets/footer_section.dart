import 'package:flutter/material.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 35, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo + description
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/andalus11.png',
                    width: 45,
                    height: 45,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Andalus',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF4B4B4B),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              const Text(
                'The complete shop management solution designed '
                'for small businesses. Simplify your operations, '
                'boost your profits, and grow with confidence.',
                style: TextStyle(
                  fontSize: 10,
                  height: 1.5,
                  color: Color.fromARGB(255, 80, 102, 126),
                ),
              ),

              const SizedBox(height: 20),

              // Social media
              Row(
                children: [
                  _SocialIcon(icon: Icons.camera_alt_outlined),
                  const SizedBox(width: 12),
                  _SocialIcon(icon: Icons.facebook),
                  const SizedBox(width: 12),
                  _SocialIcon(icon: Icons.email_outlined),
                  const SizedBox(width: 12),
                  _SocialIcon(icon: Icons.business_center_outlined),
                ],
              ),

              const SizedBox(height: 30),

              // Footer links
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FooterColumn(
                      title: 'Companies',
                      items: const [
                        'About Us',
                        'Journey',
                        'Blog',
                        'Contact',
                        'Help',
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _FooterColumn(
                      title: 'Resources',
                      items: const [
                        'About Us',
                        'Journey',
                        'Blog',
                        'Contact',
                        'Help',
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _FooterColumn(
                      title: 'Help',
                      items: const [
                        'House Rules',
                        'Our Terms',
                        'Privacy & Policy',
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Contact
              const Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF20252B),
                ),
              ),

              const SizedBox(height: 12),

              _ContactRow(icon: Icons.phone_outlined, text: '(480) 555-0103'),

              const SizedBox(height: 10),

              _ContactRow(
                icon: Icons.location_on_outlined,
                text: 'Addis Ababa, Ethiopia',
              ),

              const SizedBox(height: 10),

              _ContactRow(icon: Icons.email_outlined, text: 'Andalus@1234.com'),
            ],
          ),
        ),

        // Copyright
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          color: const Color(0xFFEEF7FB),
          child: const Text(
            'Copyright @Andalus 2025. All Rights Reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: Color.fromARGB(255, 80, 102, 126)),
          ),
        ),
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;

  const _FooterColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF20252B),
          ),
        ),

        const SizedBox(height: 10),

        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Text(
              item,
              style: const TextStyle(fontSize: 10, color: Color.fromARGB(255, 80, 102, 126),),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF61758A)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 10, color: Color.fromARGB(255, 80, 102, 126),),
          ),
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;

  const _SocialIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 35,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF252525),
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}
