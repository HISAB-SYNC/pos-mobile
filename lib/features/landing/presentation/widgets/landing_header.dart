import 'package:flutter/material.dart';

class LandingHeader extends StatelessWidget {
  const LandingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Image.asset('assets/images/andalus11.png', height: 60),
              const SizedBox(width: 8),
              const Text(
                'Andalus',
                style: TextStyle(
                  fontSize: 20,
                  letterSpacing: -0.5,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Login button
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: () {
  Navigator.of(context).pushNamed('/login');
},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Three-dot menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              // We will handle navigation later.
              debugPrint(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'home', child: Text('Home')),
              PopupMenuItem(value: 'about', child: Text('About Us')),
              PopupMenuItem(value: 'services', child: Text('Our Services')),
              PopupMenuItem(value: 'contact', child: Text('Contact Us')),
            ],
          ),
        ],
      ),
    );
  }
}
