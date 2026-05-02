import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_detail_screen.dart';

class SavedBoardScreen extends StatefulWidget {
  final String title;
  final String? listId;

  const SavedBoardScreen({
    super.key,
    required this.title,
    this.listId,
  });

  @override
  State<SavedBoardScreen> createState() => _SavedBoardScreenState();
}

class _SavedBoardScreenState extends State<SavedBoardScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> savedPosts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => loading = true);

    try {
      dynamic query = supabase
          .from('saved_posts')
          .select('places(*)')
          .eq('user_id', user.id);

      if (widget.listId != null) {
        query = query.eq('list_id', widget.listId!);
      }

      final saved = await query;

      final loadedPosts = List<Map<String, dynamic>>.from(
        (saved as List)
            .map((item) => item['places'])
            .where((place) => place != null),
      );

      if (mounted) {
        setState(() {
          savedPosts = loadedPosts;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('Saved board failed to load: $e');

      if (mounted) {
        setState(() => loading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load saved posts: $e')),
        );
      }
    }
  }

  Future<void> _refresh() async => _loadSavedPosts();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: savedPosts.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 160),
                        Icon(
                          Icons.bookmark_border,
                          size: 70,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            widget.listId == null
                                ? 'No saved posts yet'
                                : 'No posts saved to this board yet',
                          ),
                        ),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(2),
                      itemCount: savedPosts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemBuilder: (context, index) {
                        final post = savedPosts[index];

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(post: post),
                            ),
                          ),
                          child: Image.network(
                            post['image_url'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}