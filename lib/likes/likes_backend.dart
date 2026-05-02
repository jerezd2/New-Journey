import 'package:supabase_flutter/supabase_flutter.dart';

class LikesService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> enrichPlacesWithLikes(
    List<Map<String, dynamic>> rawPlaces,
  ) async {
    final user = supabase.auth.currentUser;
    final enrichedPlaces = <Map<String, dynamic>>[];

    for (final place in rawPlaces) {
      final placeId = place['id'].toString();

      final likesResponse = await supabase
          .from('likes')
          .select()
          .eq('place_id', placeId);

      final isLiked = user == null
          ? false
          : likesResponse.any((like) => like['user_id'] == user.id);

      enrichedPlaces.add({
        ...place,
        'likes_count': likesResponse.length,
        'is_liked': isLiked,
      });
    }

    return enrichedPlaces;
  }

  Future<void> toggleLike(Map<String, dynamic> place) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final placeId = place['id'].toString();
    final isLiked = place['is_liked'] == true;

    if (isLiked) {
      await supabase
          .from('likes')
          .delete()
          .eq('place_id', placeId)
          .eq('user_id', user.id);
    } else {
      await supabase.from('likes').insert({
        'place_id': placeId,
        'user_id': user.id,
      });
    }
  }
}