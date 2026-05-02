import 'package:flutter/material.dart';
import 'package:new_journey/theme/app_colors.dart';
import 'package:new_journey/theme/app_text_styles.dart';

class LikeButton extends StatelessWidget {
  final bool isLiked;
  final int likesCount;
  final VoidCallback? onTap;

  const LikeButton({
    super.key,
    required this.isLiked,
    required this.likesCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            '$likesCount',
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}