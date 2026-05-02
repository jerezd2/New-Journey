import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_detail_screen.dart';
 
class UserProfileScreen extends StatefulWidget {
  final String  userId;
  final String? scrollToPostId; 
 
  const UserProfileScreen({
    super.key,
    required this.userId,
    this.scrollToPostId,
  });
 
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}
 
class _UserProfileScreenState extends State<UserProfileScreen> {
  final supabase = Supabase.instance.client;
 
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> posts = [];
  bool loading    = true;
  bool isFollowing = false;
  bool followLoading = false;
 
  int followersCount = 0;
  int followingCount = 0;
 

  final ScrollController _scrollController = ScrollController();
  int? _highlightedPostIndex;
 
  @override
  void initState() {
    super.initState();
    _loadAll();
  }
 
  Future<void> _loadAll() async {
    await Future.wait([
      _loadProfile(),
      _checkFollowing(),
      _loadCounts(),
    ]);
    if (widget.scrollToPostId != null) _scrollToPost();
  }
 
  Future<void> _loadProfile() async {
    try {
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();
 
      final userPosts = await supabase
          .from('places')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);
 
      if (mounted) {
        setState(() {
          profile = profileData;
          posts   = List<Map<String, dynamic>>.from(userPosts);
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }
 
  Future<void> _checkFollowing() async {
    final me = supabase.auth.currentUser;
    if (me == null || me.id == widget.userId) return;
    try {
      final res = await supabase
          .from('follows')
          .select('id')
          .eq('follower_id', me.id)
          .eq('following_id', widget.userId)
          .limit(1);
      if (mounted) setState(() => isFollowing = (res as List).isNotEmpty);
    } catch (_) {}
  }
 
  Future<void> _loadCounts() async {
    try {
      final followers = await supabase
          .from('follows')
          .select('id')
          .eq('following_id', widget.userId);
      final following = await supabase
          .from('follows')
          .select('id')
          .eq('follower_id', widget.userId);
      if (mounted) {
        setState(() {
          followersCount = (followers as List).length;
          followingCount = (following as List).length;
        });
      }
    } catch (_) {}
  }
 
  Future<void> _toggleFollow() async {
    final me = supabase.auth.currentUser;
    if (me == null) return;
    setState(() => followLoading = true);
    try {
      if (isFollowing) {
        await supabase
            .from('follows')
            .delete()
            .eq('follower_id', me.id)
            .eq('following_id', widget.userId);
        setState(() { isFollowing = false; followersCount--; });
      } else {
        await supabase.from('follows').insert({
          'follower_id':  me.id,
          'following_id': widget.userId,
        });
        setState(() { isFollowing = true; followersCount++; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => followLoading = false);
    }
  }
 
  void _scrollToPost() {
    if (widget.scrollToPostId == null) return;
    final idx = posts.indexWhere((p) => p['id'] == widget.scrollToPostId);
    if (idx == -1) return;
    setState(() => _highlightedPostIndex = idx);
 
  
    WidgetsBinding.instance.addPostFrameCallback((_) {
      
      final cellSize = MediaQuery.of(context).size.width / 3;
      final row      = (idx / 3).floor();
      final offset   = row * cellSize;
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
     
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _highlightedPostIndex = null);
      });
    });
  }
 
  bool get _isOwnProfile =>
      supabase.auth.currentUser?.id == widget.userId;
 
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
 
    final avatar   = profile?['avatar_url'];
    final username = profile?['username'] ?? 'User';
    final fullName = '${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}'.trim();
    final location = '${profile?['city'] ?? ''}, ${profile?['state'] ?? ''}'.trim();
    final cleanLoc = location == ',' ? '' : location;
 
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        title: Text(username,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                        child: avatar == null
                            ? const Icon(Icons.person, size: 44, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statCol(posts.length.toString(), 'Posts'),
                            _statCol(followersCount.toString(), 'Followers'),
                            _statCol(followingCount.toString(), 'Following'),
                          ],
                        ),
                      ),
                    ],
                  ),
 
                  const SizedBox(height: 12),
 
                  if (fullName.isNotEmpty)
                    Text(fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (cleanLoc.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(cleanLoc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
 
                  const SizedBox(height: 14),
 
                 
                  if (!_isOwnProfile)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: followLoading ? null : _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing ? Colors.white : Colors.blue,
                          foregroundColor: isFollowing ? Colors.black : Colors.white,
                          side: isFollowing
                              ? BorderSide(color: Colors.grey.shade300)
                              : BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: followLoading
                            ? const SizedBox(height: 18, width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(
                                isFollowing ? 'Following' : 'Follow',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),
 
       
          const SliverToBoxAdapter(child: Divider(height: 1)),
 
      
          posts.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.photo_camera_outlined,
                              size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('No posts yet',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post      = posts[index];
                      final highlight = _highlightedPostIndex == index;
 
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailScreen(post: post),
                          ),
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            border: highlight
                                ? Border.all(color: Colors.blue, width: 3)
                                : null,
                          ),
                          child: Image.network(
                            post['image_url'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image, color: Colors.grey)),
                          ),
                        ),
                      );
                    },
                    childCount: posts.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                ),
        ],
      ),
    );
  }
 
  Widget _statCol(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
 