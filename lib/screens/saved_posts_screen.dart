import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_profile_screen.dart';
 
class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});
 
  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}
 
class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final supabase = Supabase.instance.client;
 
 
  List<Map<String, dynamic>> _savedItems = [];
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }
 
  Future<void> _loadSavedPosts() async {
    setState(() => _loading = true);
    final user = supabase.auth.currentUser;
    try {
      
      final data = await supabase
          .from('saved_posts')
          .select('post_id, places(*, profiles(id, username, avatar_url, first_name, last_name))')
          .eq('user_id', user!.id)
          .order('created_at', ascending: false);
 
    
      final Map<String, Map<String, dynamic>> uniqueMap = {};
      for (final item in data as List) {
        final place = item['places'];
        if (place != null && place['id'] != null) {
          uniqueMap[place['id']] = {
            'post':    place,
            'profile': place['profiles'],
          };
        }
      }
 
      if (mounted) {
        setState(() {
          _savedItems = uniqueMap.values.toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  Future<void> _unsavePost(String postId) async {
    final user = supabase.auth.currentUser;
    try {
      await supabase
          .from('saved_posts')
          .delete()
          .eq('user_id', user!.id)
          .eq('post_id', postId);
      setState(() => _savedItems.removeWhere((item) => item['post']['id'] == postId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post removed from saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      }
    }
  }
 
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
 
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Saved',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _savedItems.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _loadSavedPosts,
              child: GridView.builder(
                padding: const EdgeInsets.all(2),
                itemCount: _savedItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemBuilder: (context, index) {
                  final item    = _savedItems[index];
                  final post    = item['post']    as Map<String, dynamic>;
                  final profile = item['profile'] as Map<String, dynamic>?;
 
                  return GestureDetector(
                    onTap: () {
                     
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(
                            userId:        profile?['id'] ?? post['user_id'],
                            scrollToPostId: post['id'],
                          ),
                        ),
                      );
                    },
                    onLongPress: () => _showUnsaveDialog(post['id']),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          post['image_url'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      
                        Positioned(
                          bottom: 4, left: 4,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundImage: profile?['avatar_url'] != null
                                    ? NetworkImage(profile!['avatar_url']) : null,
                                backgroundColor: Colors.grey.shade400,
                                child: profile?['avatar_url'] == null
                                    ? const Icon(Icons.person, size: 10, color: Colors.white) : null,
                              ),
                            ],
                          ),
                        ),
                     
                        const Positioned(
                          top: 4, right: 4,
                          child: Icon(Icons.bookmark, color: Colors.white, size: 16,
                              shadows: [Shadow(blurRadius: 4, color: Colors.black54)]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
 
  void _showUnsaveDialog(String postId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.bookmark_remove, color: Colors.red),
              title: const Text('Remove from saved', style: TextStyle(color: Colors.red)),
              onTap: () { Navigator.pop(context); _unsavePost(postId); },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
 
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No saved posts yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Save posts to see them here',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
 