import 'package:flutter/material.dart';

/// Animated typing dots widget that shows three dots with staggered animation
/// Used to indicate when AI is typing/processing a response
class TypingDotsWidget extends StatefulWidget {
  final Color? color;
  final double size;
  final Duration animationDuration;

  const TypingDotsWidget({
    super.key,
    this.color,
    this.size = 8.0,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<TypingDotsWidget> createState() => _TypingDotsWidgetState();
}

class _TypingDotsWidgetState extends State<TypingDotsWidget> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    // Create 3 animation controllers for each dot
    _controllers = List.generate(
      3,
      (index) => AnimationController(duration: widget.animationDuration, vsync: this),
    );

    // Create animations for each dot with staggered timing
    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.4,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    // Start animations with staggered delays
    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor =
        widget.color ??
        Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6) ??
        Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.15),
              child: Opacity(
                opacity: _animations[index].value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
