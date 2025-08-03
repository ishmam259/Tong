import 'package:flutter/material.dart';

class TongLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;

  const TongLogo({
    super.key,
    this.size = 48,
    this.showText = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Use actual logo image from assets
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.2),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: size * 0.1,
                offset: Offset(0, size * 0.05),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.2),
            child: Image.asset(
              'assets/images/2.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to custom painted logo if image fails to load
                return _buildCustomLogo(context);
              },
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            'Tong',
            style: TextStyle(
              fontSize: size * 0.3,
              fontWeight: FontWeight.bold,
              color: textColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomLogo(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Coffee cup base
          Container(
            width: size * 0.6,
            height: size * 0.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.1),
            ),
          ),
          // Coffee cup handle
          Positioned(
            right: size * 0.15,
            child: Container(
              width: size * 0.15,
              height: size * 0.25,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: size * 0.03),
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
            ),
          ),
          // Message bubbles
          Positioned(
            top: size * 0.1,
            left: size * 0.25,
            child: Container(
              width: size * 0.15,
              height: size * 0.1,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(size * 0.05),
              ),
            ),
          ),
          Positioned(
            top: size * 0.25,
            right: size * 0.25,
            child: Container(
              width: size * 0.12,
              height: size * 0.08,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(size * 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedTongLogo extends StatefulWidget {
  final double size;
  final bool showText;
  final Color? textColor;

  const AnimatedTongLogo({
    super.key,
    this.size = 48,
    this.showText = true,
    this.textColor,
  });

  @override
  _AnimatedTongLogoState createState() => _AnimatedTongLogoState();
}

class _AnimatedTongLogoState extends State<AnimatedTongLogo>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Start animations
    _scaleController.repeat(reverse: true);
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _rotationController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: TongLogo(
              size: widget.size,
              showText: widget.showText,
              textColor: widget.textColor,
            ),
          ),
        );
      },
    );
  }
}
