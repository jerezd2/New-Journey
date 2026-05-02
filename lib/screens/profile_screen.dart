import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_app/screens/setting_screens.dart';
import 'edit_profile_screen.dart';
import 'post_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> posts = [];
  bool loading = true;
  int followersCount = 0;
  int followingCount = 0;

  static const _kOrange  = Color(0xFFE8640A);
  static const _kGreen   = Color(0xFF6B7D3C);
  static const _kBeige   = Color(0xFFFAF8F5);
  static const _kBrown   = Color(0xFF8B5A2B);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    setState(() => loading = true);
    try {
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final userPosts = await supabase
          .from('places')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final followers = await supabase
          .from('follows')
          .select('id')
          .eq('following_id', user.id);

      final following = await supabase
          .from('follows')
          .select('id')
          .eq('follower_id', user.id);

      if (mounted) {
        setState(() {
          profile        = profileData;
          posts          = List<Map<String, dynamic>>.from(userPosts);
          followersCount = (followers as List).length;
          followingCount = (following as List).length;
          loading        = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _refresh() async => _loadAll();

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final username  = profile?['username'] ?? 'Explorer';
    final firstName = profile?['first_name'] ?? '';
    final lastName  = profile?['last_name'] ?? '';
    final fullName  = '$firstName $lastName'.trim();
    final city      = profile?['city'] ?? '';
    final state     = profile?['state'] ?? '';
    final location  = (city.isNotEmpty && state.isNotEmpty)
        ? '$city, $state'
        : (city + state);
    final bio    = profile?['bio'] ?? '';
    final avatar = profile?['avatar_url'];

    return Scaffold(
      backgroundColor: _kBeige,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [

            SliverToBoxAdapter(
              child: Stack(
                children: [
                  // Banner gradient
                  Container(
                    height: 160,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_kBrown, _kOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Opacity(
                      opacity: 0.15,
                      child: Image.asset(
                        'assets/images/brown-bear-logo.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  ),
                 
                  Positioned(
                    top: 40,
                    right: 16,
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        );
                        _refresh();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.settings_outlined,
                            size: 20, color: _kBrown),
                      ),
                    ),
                  ),
                  // Avatar overlapping the banner
                  Positioned(
                    bottom: 0,
                    left: 20,
                    child: Transform.translate(
                      offset: const Offset(0, 40),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _kBeige, width: 4),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12,
                              color: Colors.black.withOpacity(0.18),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage:
                              avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null
                              ? const Icon(Icons.person,
                                  size: 46, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@$username',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: _kOrange,
                                ),
                              ),
                              if (fullName.isNotEmpty)
                                Text(fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const EditProfileScreen()));
                            _refresh();
                          },
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: const Text('Edit Profile',
                              style: TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kBrown,
                            side: const BorderSide(color: _kBrown),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),

                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.explore_outlined,
                              size: 14, color: _kOrange),
                          const SizedBox(width: 4),
                          Text(location,
                              style: const TextStyle(
                                  color: _kOrange, fontSize: 13)),
                        ],
                      ),
                    ],

                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(bio,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700)),
                    ],

                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statCol(posts.length.toString(),
                              'Places', Icons.place_outlined),
                          _divider(),
                          _statCol(followersCount.toString(),
                              'Followers', Icons.people_outline),
                          _divider(),
                          _statCol(followingCount.toString(),
                              'Following', Icons.person_add_alt_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library_outlined,
                        size: 18, color: _kBrown),
                    const SizedBox(width: 6),
                    const Text('My Adventures',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _kBrown)),
                    const Spacer(),
                    Text('${posts.length} places',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),

            posts.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.terrain,
                                size: 64,
                                color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('No adventures yet',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Start exploring and add your first place!',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = posts[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PostDetailScreen(post: post),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    post['image_url'] ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image,
                                            color: Colors.grey)),
                                  ),
                                
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.55),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      child: Text(
                                        post['name'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: posts.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        height: 32,
        width: 1,
        color: Colors.grey.shade200,
      );

  Widget _statCol(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: _kOrange),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}