import 'package:flutter/material.dart';
import '../utils/theme.dart';

enum ShootingStarColor { purple, cyan, pink }

class ShootingStar {
  final double delay;
  final ShootingStarColor color;
  final Offset startPosition;
  
  ShootingStar({
    required this.delay,
    required this.color,
    required this.startPosition,
  });
}

class ShootingStarsWidget extends StatefulWidget {
  final ShootingStar star;
  
  const ShootingStarsWidget({super.key, required this.star});
  
  @override
  State<ShootingStarsWidget> createState() => _ShootingStarsWidgetState();
}

class _ShootingStarsWidgetState extends State<ShootingStarsWidget> 
    with SingleTickerProviderStateMixin {
      
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Delay the animation
    Future.delayed(Duration(milliseconds: (widget.star.delay * 1000).toInt()), () {
      if (mounted) {
        _controller.repeat();
      }
    });
    
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        if (_animation.value == 0) return const SizedBox.shrink();
        
        final progress = _animation.value;
        final color = widget.star.color == ShootingStarColor.purple 
          ? AppTheme.primary
          : widget.star.color == ShootingStarColor.cyan
            ? AppTheme.secondary
            : AppTheme.accent;
        
        final endX = widget.star.startPosition.dx + 200 * progress;
        final endY = widget.star.startPosition.dy + 200 * progress;
        
        return CustomPaint(
          painter: ShootingStarPainter(
            start: widget.star.startPosition,
            end: Offset(endX, endY),
            color: color,
            opacity: 1 - progress,
          ),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class ShootingStarPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  final double opacity;
  
  ShootingStarPainter({
    required this.start,
    required this.end,
    required this.color,
    required this.opacity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(start, end, paint);
    
    // Add glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawLine(start, end, glowPaint);
  }
  
  @override
  bool shouldRepaint(ShootingStarPainter oldDelegate) {
    return oldDelegate.start != start ||
           oldDelegate.end != end ||
           oldDelegate.opacity != opacity;
  }
}

