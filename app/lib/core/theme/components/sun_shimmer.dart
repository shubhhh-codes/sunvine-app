import 'package:flutter/material.dart';
import '../app_colors.dart';

class SunShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SunShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<SunShimmer> createState() => _SunShimmerState();
}

class _SunShimmerState extends State<SunShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + (_controller.value * 3), 0),
              end: Alignment(-0.5 + (_controller.value * 3), 0),
              colors: const [
                AppColors.surface,
                AppColors.surfaceSubtle,
                AppColors.surface,
              ],
            ),
          ),
        );
      },
    );
  }
}
