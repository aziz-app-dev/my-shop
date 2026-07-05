// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../view_models/providers/profile_provider.dart';
import '../view_models/services/splash_services.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final SplashServices splashScreen = SplashServices();

  @override
  void initState() {
    super.initState();
    ref.read(profileProvider.notifier).loadUserData();

    // Delay navigation until after first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      splashScreen.isLogin(ref, context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (profileState.shopName != null &&
                  profileState.shopLogo != null) ...[
                Image.file(
                  profileState.shopLogo!,
                  height: 100.h,
                  width: 100.h,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Icon(Icons.store, size: 100.sp, color: Colors.white),
                ),
                SizedBox(height: 20.h),
                Text(
                  profileState.shopName!,
                  style: TextStyle(
                    fontSize: 30.spMin,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AdvancedSplashScreen extends StatefulWidget {
  final Duration duration;
  final Widget nextScreen;

  const AdvancedSplashScreen({
    super.key,
    this.duration = const Duration(seconds: 3),
    required this.nextScreen,
  });

  @override
  _AdvancedSplashScreenState createState() => _AdvancedSplashScreenState();
}

class _AdvancedSplashScreenState extends State<AdvancedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashTimer();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _colorAnimation = ColorTween(
      begin: Colors.blue.shade50,
      end: Colors.blue.shade100,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  void _startSplashTimer() {
    Timer(widget.duration, () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => widget.nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [_colorAnimation.value!, Colors.blue.shade200],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with scale and fade animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.flutter_dash,
                          size: 60,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App name with slide animation
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'My Awesome App',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tagline with delayed animation
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Experience the Future',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Loading indicator
                  _buildLoadingIndicator(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 100,
      height: 4,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FractionallySizedBox(
                widthFactor: _controller.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.blue.shade100],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ParticleSplashScreen extends StatefulWidget {
  final Duration duration;
  final Widget nextScreen;

  const ParticleSplashScreen({
    super.key,
    this.duration = const Duration(seconds: 4),
    required this.nextScreen,
  });

  @override
  _ParticleSplashScreenState createState() => _ParticleSplashScreenState();
}

class _ParticleSplashScreenState extends State<ParticleSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..forward();

    _initializeParticles();
    _startSplashTimer();
  }

  void _initializeParticles() {
    _particles = List.generate(30, (index) => Particle(_random));
  }

  void _startSplashTimer() {
    Timer(widget.duration, () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => widget.nextScreen),
      );
    });
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.purple.shade700],
          ),
        ),
        child: Stack(
          children: [
            // Animated particles
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                _updateParticles();
                return CustomPaint(
                  painter: ParticlePainter(_particles, _controller.value),
                );
              },
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  AnimatedContainer(
                    duration: Duration(milliseconds: 1000),
                    curve: Curves.elasticOut,
                    width: _controller.value * 120,
                    height: _controller.value * 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(Icons.star, size: 60, color: Colors.amber),
                  ),

                  const SizedBox(height: 40),

                  // App name with typing effect
                  _buildTypingText(),

                  const SizedBox(height: 50),

                  // Pulsing loading text
                  _buildPulsingLoader(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingText() {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 1500),
      tween: IntTween(begin: 0, end: 'Welcome to MyApp'.length),
      builder: (context, value, child) {
        return Text(
          'Welcome to MyApp'.substring(0, value),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        );
      },
    );
  }

  Widget _buildPulsingLoader() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + 0.5 * sin(_controller.value * 2 * pi),
          child: Text(
            'Loading...',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        );
      },
    );
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.update();
    }
  }
}

class Particle {
  final Random random;
  late double x, y;
  late double vx, vy;
  late double size;
  late Color color;
  late double alpha;

  Particle(this.random) {
    reset();
  }

  void reset() {
    x = random.nextDouble() * 400 - 200;
    y = random.nextDouble() * 400 - 200;
    vx = random.nextDouble() * 2 - 1;
    vy = random.nextDouble() * 2 - 1;
    size = random.nextDouble() * 3 + 1;
    color = Colors.white.withOpacity(random.nextDouble() * 0.5 + 0.1);
    alpha = 1.0;
  }

  void update() {
    x += vx;
    y += vy;
    alpha -= 0.01;

    if (alpha <= 0) {
      reset();
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var particle in particles) {
      paint.color = particle.color.withOpacity(particle.alpha * progress);
      canvas.drawCircle(
        Offset(particle.x + size.width / 2, particle.y + size.height / 2),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class EnhancedParticleSplashScreen extends StatefulWidget {
  final Duration duration;
  final Widget nextScreen;

  const EnhancedParticleSplashScreen({
    super.key,
    this.duration = const Duration(seconds: 4),
    required this.nextScreen,
  });

  @override
  _EnhancedParticleSplashScreenState createState() =>
      _EnhancedParticleSplashScreenState();
}

class _EnhancedParticleSplashScreenState
    extends State<EnhancedParticleSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<EnhancedParticle> _particles;
  final Random _random = Random();
  final int _particleCount = 50;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..forward();

    _initializeParticles();
    _startSplashTimer();
  }

  void _initializeParticles() {
    _particles = List.generate(
      _particleCount,
      (index) => EnhancedParticle(_random, _controller),
    );
  }

  void _startSplashTimer() {
    Timer(widget.duration, () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => widget.nextScreen),
      );
    });
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
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Colors.blue.shade900,
              Colors.purple.shade900,
              Colors.black,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated particles
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                _updateParticles();
                return CustomPaint(
                  painter: EnhancedParticlePainter(
                    _particles,
                    _controller.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 3D Rotating Logo
                  _buildRotatingLogo(),

                  const SizedBox(height: 40),

                  // Glowing Text
                  _buildGlowingText(),

                  const SizedBox(height: 50),

                  // Animated Progress Bar
                  _buildAnimatedProgressBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRotatingLogo() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_controller.value * 2 * pi),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(Icons.rocket_launch, size: 50, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildGlowingText() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Text(
          'SPACE APP',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 3,
            shadows: [
              Shadow(
                color: Colors.blue.withOpacity(
                  0.8 + 0.2 * sin(_controller.value * 4 * pi),
                ),
                blurRadius: 20,
              ),
              Shadow(
                color: Colors.purple.withOpacity(
                  0.8 + 0.2 * cos(_controller.value * 4 * pi),
                ),
                blurRadius: 30,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedProgressBar() {
    return Container(
      width: 200,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _controller.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.update();
    }
  }
}

class EnhancedParticle {
  final Random random;
  final AnimationController controller;
  late double x, y;
  late double vx, vy;
  late double baseSize;
  late double size;
  late Color color;
  late double alpha;
  late double growthRate;

  EnhancedParticle(this.random, this.controller) {
    reset();
  }

  void reset() {
    x = random.nextDouble() * 400 - 200;
    y = random.nextDouble() * 400 - 200;
    vx = random.nextDouble() * 2 - 1;
    vy = random.nextDouble() * 2 - 1;
    baseSize = random.nextDouble() * 5 + 1;
    size = baseSize;
    color =
        [Colors.blue, Colors.purple, Colors.white, Colors.cyan][random.nextInt(
          4,
        )];
    alpha = random.nextDouble() * 0.8 + 0.2;
    growthRate =
        random.nextDouble() * 0.5 + 0.1; // Growth rate for each particle
  }

  void update() {
    x += vx;
    y += vy;

    // Increase size over time based on controller progress
    size = baseSize * (1 + controller.value * growthRate * 5);

    // Pulsing alpha effect
    alpha = 0.3 + 0.7 * (0.5 + 0.5 * sin(controller.value * 4 * pi + x));

    if (alpha <= 0 || size > 50) {
      reset();
      size = baseSize;
    }
  }
}

class EnhancedParticlePainter extends CustomPainter {
  final List<EnhancedParticle> particles;
  final double progress;

  EnhancedParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      paint.color = particle.color.withOpacity(particle.alpha * progress);

      // Draw main circle
      canvas.drawCircle(
        Offset(particle.x + size.width / 2, particle.y + size.height / 2),
        particle.size,
        paint,
      );

      // Draw glow effect for larger particles
      if (particle.size > 8) {
        paint.color = particle.color.withOpacity(
          particle.alpha * 0.3 * progress,
        );
        canvas.drawCircle(
          Offset(particle.x + size.width / 2, particle.y + size.height / 2),
          particle.size * 1.5,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
