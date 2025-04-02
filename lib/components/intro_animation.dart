import 'package:flutter/material.dart';
import '../managers/gameLayoutManager.dart';
import '../styles/app_styles.dart';
import 'dart:math' as math;

class IntroAnimation extends StatefulWidget {
  final GameLayoutManager gameLayoutManager;
  final VoidCallback onComplete;

  const IntroAnimation({super.key, required this.gameLayoutManager, required this.onComplete});

  @override
  State<IntroAnimation> createState() => _IntroAnimationState();
}

class _IntroAnimationState extends State<IntroAnimation> with TickerProviderStateMixin {
  // Animation durations
  static const int letterAnimationDuration = 100; // Duration for each letter animation
  static const int sloganAnimationDuration = 800; // Duration for slogan animation
  static const int logoAnimationDuration = 1000; // Duration for logo animations

  // Delays between animations
  static const int delayBetweenLetters = 500; // Delay between each letter animation
  static const int delayAfterLetters = 1000; // Delay after all letters finish
  static const int delayAfterSlogan = 1000; // Delay after slogan finishes
  static const int finalDelay = 2000; // Final delay before completion

  // Animation distances
  static const double logoOffsetExtra = 50.0; // Extra pixels beyond screen edge for logos
  static const double sloganOffsetExtra = 50.0; // Extra pixels beyond screen edge for slogan

  late List<AnimationController> _letterControllers;
  late AnimationController _sloganController;
  late List<AnimationController> _logoControllers;

  late List<Animation<Offset>> _letterSlideAnimations;
  late List<Animation<double>> _letterScaleAnimations;
  late List<Animation<double>> _letterRotateAnimations;
  late Animation<Offset> _sloganSlideAnimation;
  late List<Animation<Offset>> _logoSlideAnimations;

  final String title = "RE-WORD";
  final String slogan = "Re-Think. Re-Use. Re-Word!";

  // Starting positions for letters (random positions around the screen)
  final List<Offset> _startPositions = [
    const Offset(-2.0, -2.0), // Top left
    const Offset(2.0, -2.0), // Top right
    const Offset(-2.0, 2.0), // Bottom left
    const Offset(2.0, 2.0), // Bottom right
    const Offset(0.0, -2.0), // Top center
    const Offset(0.0, 2.0), // Bottom center
    const Offset(-2.0, 0.0), // Left center
    const Offset(2.0, 0.0), // Right center
  ];

  @override
  void initState() {
    super.initState();

    // Letter animations
    _letterControllers = List.generate(
      title.length,
      (index) => AnimationController(duration: Duration(milliseconds: letterAnimationDuration), vsync: this),
    );

    _letterSlideAnimations =
        _letterControllers.map((controller) {
          final startPos = _startPositions[math.Random().nextInt(_startPositions.length)];
          return Tween<Offset>(
            begin: startPos,
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
        }).toList();

    _letterScaleAnimations =
        _letterControllers.map((controller) {
          return Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
        }).toList();

    _letterRotateAnimations =
        _letterControllers.map((controller) {
          return Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
        }).toList();

    // Slogan animation
    _sloganController = AnimationController(duration: Duration(milliseconds: sloganAnimationDuration), vsync: this);

    // Logo animations
    _logoControllers = List.generate(
      2,
      (index) => AnimationController(duration: Duration(milliseconds: logoAnimationDuration), vsync: this),
    );

    // Start animations in sequence
    _startAnimations();
  }

  void _startAnimations() async {
    // Start letter animations one by one
    for (int i = 0; i < title.length; i++) {
      await Future.delayed(Duration(milliseconds: delayBetweenLetters));
      _letterControllers[i].forward();
    }

    // Wait for letters to finish
    await Future.delayed(Duration(milliseconds: delayAfterLetters));

    // Start slogan animation
    _sloganController.forward();

    // Wait for slogan to finish
    await Future.delayed(Duration(milliseconds: delayAfterSlogan));

    // Start logo animations
    for (var controller in _logoControllers) {
      controller.forward();
    }

    // Wait for everything to finish
    await Future.delayed(Duration(milliseconds: finalDelay));

    // Call onComplete
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    for (var controller in _letterControllers) {
      controller.dispose();
    }
    _sloganController.dispose();
    for (var controller in _logoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final logoOffset = screenWidth / 2 + logoOffsetExtra; // Start beyond the screen edge
    final sloganOffset = screenHeight / 2 + sloganOffsetExtra; // Start beyond the bottom edge

    _sloganSlideAnimation = Tween<Offset>(
      begin: Offset(0, sloganOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sloganController, curve: Curves.elasticOut));

    _logoSlideAnimations =
        _logoControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Tween<Offset>(
            begin: Offset(index == 0 ? -logoOffset : logoOffset, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
        }).toList();

    return Container(
      color: const Color.fromARGB(255, 2, 2, 2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title letters
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(title.length, (index) {
                return AnimatedBuilder(
                  animation: _letterControllers[index],
                  builder: (context, child) {
                    final angle = (index % 2 == 0) ? 10 * math.pi / 180 : -10 * math.pi / 180;
                    final finalRotation = angle * _letterRotateAnimations[index].value;

                    return Transform.translate(
                      offset: _letterSlideAnimations[index].value,
                      child: Transform.scale(
                        scale: _letterScaleAnimations[index].value,
                        child: Transform.rotate(
                          angle: finalRotation,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              title[index],
                              style: TextStyle(
                                fontSize: widget.gameLayoutManager.titleFontSize * 1.5,
                                fontWeight: FontWeight.bold,
                                color: AppStyles.headerTextColor,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            // Slogan
            AnimatedBuilder(
              animation: _sloganController,
              builder: (context, child) {
                return Transform.translate(
                  offset: _sloganSlideAnimation.value,
                  child: Text(
                    slogan,
                    style: TextStyle(
                      fontSize: widget.gameLayoutManager.sloganFontSize,
                      fontWeight: FontWeight.normal,
                      color: AppStyles.titleSloganTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Logos
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flutter Logo
                AnimatedBuilder(
                  animation: _logoControllers[0],
                  builder: (context, child) {
                    return Transform.translate(
                      offset: _logoSlideAnimations[0].value,
                      child: const FlutterLogo(size: 32, style: FlutterLogoStyle.markOnly),
                    );
                  },
                ),
                const SizedBox(width: 32),
                // Digital Relics Logo
                AnimatedBuilder(
                  animation: _logoControllers[1],
                  builder: (context, child) {
                    return Transform.translate(
                      offset: _logoSlideAnimations[1].value,
                      child: Image.asset('assets/images/DR_TRANSPARENT.png', width: 32),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
