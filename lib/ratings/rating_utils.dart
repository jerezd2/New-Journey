double calculateAverageRating(List ratings) {
  if (ratings.isEmpty) return 0;

  final total = ratings.fold<double>(
    0,
        (sum, r) => sum + (r['rating_score'] as num).toDouble(),
  );

  return total / ratings.length;
}

int getRatingCount(List ratings) {
  return ratings.length;
}