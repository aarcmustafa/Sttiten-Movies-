import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants.dart';
import '../../../core/main_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // أنيميشن الشعار (تكبير ونبض)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // أنيميشن النص (ظهور وانزلاق)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // بدء الأنيميشن
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();

    // الاستماع لانتهاء الصوت
    _audioPlayer.onPlayerComplete.listen((event) {
      _navigateToMain();
    });

    // تشغيل الصوت
    try {
      await _audioPlayer.play(AssetSource('audio/welcome.mp3'));
    } catch (e) {
      debugPrint('Audio failed to load: $e');
      // إذا فشل الصوت، ننتقل بعد 3 ثوانٍ
      Future.delayed(const Duration(seconds: 3), _navigateToMain);
    }

    // خطة بديلة: مهما حدث، لا تجعل المستخدم عالقاً أكثر من 10 ثوانٍ
    Timer(const Duration(seconds: 10), _navigateToMain);
  }

  void _navigateToMain() {
    if (_isNavigating) return;
    _isNavigating = true;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScaffold(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _audioPlayer.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // الشعار المتحرك
            ScaleTransition(
              scale: _scaleAnimation,
              child: SvgPicture.asset(
                'assets/images/logo.svg',
                width: 140,
                height: 140,
              ),
            ),
            
            const SizedBox(height: 30),

            // النص المتحرك
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      'STTITEN',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4.0,
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ).createShader(bounds),
                      child: const Text(
                        'MOVIES',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white, // سيتم استبداله بالتدرج اللوني
                          letterSpacing: 8.0,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 50),

            // مؤشر تحميل صغير وناعم
            FadeTransition(
              opacity: _fadeAnimation,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
