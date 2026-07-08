import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        fadeRoute(const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fond/fond_splash.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo/logo_bleu.png',
                  width: 150,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Relio',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: AppColors.marine,
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: AppColors.roseViolet,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
