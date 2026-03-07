import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.score,
    required this.total,
    this.size = 36,
    this.maxStars = 3,
  });

  final int score;
  final int total;
  final double size;
  final int maxStars;

  int get _stars {
    if (total == 0) return 0;
    final pct = score / total;
    if (pct >= 0.9) return 3;
    if (pct >= 0.6) return 2;
    if (pct > 0) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final filled = _stars;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (i) {
        return Icon(
          i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: i < filled ? AppColors.starFilled : AppColors.starEmpty,
          size: size,
        );
      }),
    );
  }
}
