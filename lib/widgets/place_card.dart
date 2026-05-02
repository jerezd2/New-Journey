import 'package:flutter/material.dart';
import 'package:supabase_app/theme/app_colors.dart';
import 'package:supabase_app/theme/app_text_styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_app/ratings/rating_utils.dart';
import 'package:supabase_app/ratings/rating_display.dart';

class PlaceCard extends StatefulWidget {
  final Map<String, dynamic> place;
  final VoidCallback? onRateTap;

  const PlaceCard({
    super.key,
    required this.place,
    this.onRateTap,
  });

  @override
  State<PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  late bool isSaved;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    isSaved = (widget.place['saved_by_user'] ?? false);
  }

  Future<void> toggleBookmark() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (isSaved) {
      await supabase
          .from('saved_posts')
          .delete()
          .eq('user_id', user.id)
          .eq('post_id', widget.place['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from saved posts')));
      }
    } else {
      await supabase.from('saved_posts').insert({
        'user_id': user.id,
        'post_id': widget.place['id'],
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved!')));
      }
    }

    setState(() {
      isSaved = !isSaved;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ratings = widget.place['ratings'] ?? [];
    final avgRating = calculateAverageRating(ratings);
    final ratingCount = getRatingCount(ratings);

    return GestureDetector(
      onTap: widget.onRateTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 6),
              color: AppColors.shadow,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (widget.place['image_url'] != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: Image.network(
                      widget.place['image_url'],
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: toggleBookmark,
                    child: CircleAvatar(
                      backgroundColor: Colors.white70,
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place['name'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((widget.place['category'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.place['category'],
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RatingDisplay(
                      rating: avgRating,
                      count: ratingCount,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}