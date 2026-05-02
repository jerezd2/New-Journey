import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_app/theme/app_colors.dart';
import 'package:supabase_app/widgets/place_card.dart';
import 'package:supabase_app/ratings/rating_service.dart';
import 'package:supabase_app/ratings/rating_dialog.dart';
import 'package:supabase_app/screens/auth_screen.dart';

class HomeScreenUI extends StatefulWidget {
  const HomeScreenUI({super.key});

  @override
  State<HomeScreenUI> createState() => _HomeScreenUIState();
}

class _HomeScreenUIState extends State<HomeScreenUI> {
  final supabase = Supabase.instance.client;
  final ratingService = RatingService();

  List<Map<String, dynamic>> places = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlaces();
  }

  Future<void> fetchPlaces() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('places')
          .select(
              '*, profiles(username, avatar_url), ratings(place_id, rating_score), saved_posts(user_id)')
          .order('created_at', ascending: false);

      final data = (response as List).map((place) {
        final map = Map<String, dynamic>.from(place);
        final savedList = map['saved_posts'] as List? ?? [];
        final currentUserId = supabase.auth.currentUser?.id;
        map['saved_by_user'] =
            savedList.any((s) => s['user_id'] == currentUserId);
        return map;
      }).toList();

      setState(() {
        places = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load places: $e')));
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _HomeHeader(onRefresh: fetchPlaces),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : places.isEmpty
                      ? const Center(child: Text('No places yet'))
                      : RefreshIndicator(
                          onRefresh: fetchPlaces,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: MasonryGridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 18,
                              itemCount: places.length,
                              itemBuilder: (context, index) {
                                return PlaceCard(
                                  place: places[index],
                                  onRateTap: () async {
                                    final rating =
                                        await showRatingDialog(context);
                                    if (rating != null && rating > 0) {
                                      await ratingService.submitRating(
                                        placeId: places[index]['id'],
                                        rating: rating,
                                      );
                                      fetchPlaces();
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  const _HomeHeader({required this.onRefresh});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, 4),
              color: AppColors.shadow,
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/brown-bear-logo.png',
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const Text(
                    'Ready to start a new journey?',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, color: AppColors.brown),
            ),
          ],
        ),
      ),
    );
  }
}