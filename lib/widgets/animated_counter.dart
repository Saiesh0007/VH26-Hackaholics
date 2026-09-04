import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle style;
  final String suffix;
  final String prefix;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: value.toDouble(), end: value.toDouble()),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        final formatted = val.toInt().toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            );
        return Text(
          '$prefix$formatted$suffix',
          style: style,
        );
      },
    );
  }
}
