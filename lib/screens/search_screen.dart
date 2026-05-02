import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_app/widgets/place_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final supabase = Supabase.instance.client;

  List results = [];
  bool loading = false;

  Future<void> search(String query) async {
    if (query.isEmpty) return;
    setState(() => loading = true);

    final data = await supabase
        .from('places')
        .select(
            '*, profiles(username, avatar_url), ratings(place_id, rating_score), saved_posts(user_id)')
        .ilike('name', '%$query%');

    final currentUserId = supabase.auth.currentUser?.id;
    final mapped = (data as List).map((place) {
      final map = Map<String, dynamic>.from(place);
      final savedList = map['saved_posts'] as List? ?? [];
      map['saved_by_user'] =
          savedList.any((s) => s['user_id'] == currentUserId);
      return map;
    }).toList();

    setState(() {
      results = mapped;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: search,
              decoration: InputDecoration(
                hintText: 'Search places...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : results.isEmpty
                  ? const Center(child: Text('Search something...'))
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        return PlaceCard(place: results[index]);
                      },
                    ),
        ),
      ],
    );
  }
}