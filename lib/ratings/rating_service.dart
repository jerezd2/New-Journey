import 'package:supabase_flutter/supabase_flutter.dart';

class RatingService {
  final supabase = Supabase.instance.client;

  Future<void> submitRating({
    required String placeId,
    required double rating,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    await supabase.from('ratings').upsert({
      'place_id': placeId,
      'user_id': user.id,
      'rating_score': rating,
    });
  }
}