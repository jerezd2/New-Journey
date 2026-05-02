import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_screen.dart';
import 'change_password.dart';
import 'saved_posts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final supabase = Supabase.instance.client;

  bool _isPrivate   = false;
  bool _loadingPrivacy = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySetting();
  }

  Future<void> _loadPrivacySetting() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final data = await supabase
          .from('profiles')
          .select('is_private')
          .eq('id', user.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _isPrivate      = (data?['is_private'] as bool?) ?? false;
          _loadingPrivacy = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPrivacy = false);
    }
  }

  Future<void> _togglePrivacy(bool value) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _isPrivate = value);
    try {
      await supabase
          .from('profiles')
          .update({'is_private': value})
          .eq('id', user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value
                ? 'Account set to Private'
                : 'Account set to Public'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {

      if (mounted) {
        setState(() => _isPrivate = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        title: const Text('Settings',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        children: [

          _sectionHeader('Account'),

          _tile(
            context,
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EditProfileScreen())),
          ),
          _tile(
            context,
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen())),
          ),
          _tile(
            context,
            icon: Icons.bookmark_border,
            title: 'Saved Posts',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SavedPostsScreen())),
          ),

          const SizedBox(height: 8),
          _sectionHeader('Privacy & Security'),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Colors.black87, size: 22),
                ),
                title: const Text('Private Account',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(
                  _isPrivate
                      ? 'Only approved followers can see your posts'
                      : 'Anyone can see your posts and profile',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
                trailing: _loadingPrivacy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : Switch.adaptive(
                        value: _isPrivate,
                        activeColor: const Color(0xFF6B7D3C),
                        onChanged: _togglePrivacy,
                      ),
              ),
            ),
          ),

          _tile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () => _comingSoon(context),
          ),

          const SizedBox(height: 8),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              onPressed: () => _logout(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Log Out',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? Colors.black87, size: 22),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color ?? Colors.black87)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500))
          : null,
      trailing:
          const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}