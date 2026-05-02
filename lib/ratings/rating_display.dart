import 'package:flutter/material.dart';

class RatingDisplay extends StatelessWidget {
  final double rating;
  final int count;

  const RatingDisplay({
    super.key,
    required this.rating,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const Text(
        'No ratings yet',
        style: TextStyle(fontSize: 12),
      );
    }

    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            if (index < rating.floor()) {
              return const Icon(Icons.star, size: 16, color: Colors.amber);
            } else if (index < rating) {
              return const Icon(Icons.star_half, size: 16, color: Colors.amber);
            } else {
              return const Icon(Icons.star_border, size: 16, color: Colors.amber);
            }
          }),
        ),
        const SizedBox(width: 6),
        Text(
          '${rating.toStringAsFixed(1)} ($count)',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}