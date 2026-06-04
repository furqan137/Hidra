import 'dart:io';

import 'package:flutter/material.dart';
import '../../features/settings/hide_app/hide_app_controller.dart';
import '../../features/settings/hide_app/fake_dialer_screen.dart';
import 'splash_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;

  final SplashController _splashController = SplashController();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    /// LOGO – soft breathe
    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    /// TEXT – delayed reveal
    _titleFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();

    _startFlow();
  }

  // ================= START FLOW =================

  Future<void> _startFlow() async {
    await Future.delayed(const Duration(milliseconds: 1700));

    if (!mounted) return;

    // Android → unchanged behavior
    if (Platform.isAndroid) {
      _splashController.startTimer(context);
      return;
    }

    // iOS stealth logic
    final canOpenVault = await HideAppController.canOpenIOSVault();

    if (!mounted) return;

    if (canOpenVault) {
      _splashController.startTimer(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FakeDialerScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF050B18),
              Color(0xFF0FB9B1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              /// LOGO
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Image.asset(
                    'assets/images/Hidra_logo.png',
                    width: 120,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// TITLE + TAGLINE
              FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: Column(
                    children: const [
                      Text(
                        'Hidra',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.4,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Secure Private Vault',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}