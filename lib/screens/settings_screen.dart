import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'edit_profile_screen.dart';
import 'change_password.dart';
import 'saved_posts_screen.dart';
import 'mfa_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final supabase = Supabase.instance.client;

  bool _loadingMfa     = false;
  bool _mfaEnabled     = true;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMfaState();
  }

  Future<void> _loadMfaState() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final res = await supabase
          .from('profiles')
          .select('mfa_enabled')
          .eq('id', userId)
          .maybeSingle();

      setState(() {
        _mfaEnabled     = res?['mfa_enabled'] ?? true;
        _initialLoading = false;
      });
    } catch (_) {
      setState(() => _initialLoading = false);
    }
  }

  Future<void> _toggleMfa(bool value) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (value == true) {
      setState(() => _loadingMfa = true);
      try {
        //clean up existing factors
        try {
          final existing = await supabase.auth.mfa.listFactors();
          for (final f in existing.totp) {
            await supabase.auth.mfa.unenroll(f.id);
          }
        } catch (_) {}

        final factor = await supabase.auth.mfa.enroll(
          friendlyName: 'Google Authenticator',
          factorType: FactorType.totp,
          issuer: 'NewJourney',
        );

        if (!mounted) return;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MfaSetupScreen(
              factorId: factor.id,
              secret: factor.totp!.secret,
              onVerified: () async {
                await supabase
                    .from('profiles')
                    .update({'mfa_enabled': true})
                    .eq('id', user.id);
              },
            ),
          ),
        );

        await _loadMfaState();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to enable MFA: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _loadingMfa = false);
      }
      return;
    }

    final codeController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Disable 2FA?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your 6-digit authenticator code to confirm.'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: '6-digit code',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disable', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      codeController.dispose();
      return;
    }

    final code = codeController.text.trim();
    codeController.dispose();

    if (code.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your authenticator code')),
      );
      }
      return;
    }

    setState(() => _loadingMfa = true);

    try {
      final factors     = await supabase.auth.mfa.listFactors();
      final totpFactors = factors.totp;

      if (totpFactors.isNotEmpty) {
        final challenge = await supabase.auth.mfa.challenge(
          factorId: totpFactors.first.id,
        );
        await supabase.auth.mfa.verify(
          factorId: totpFactors.first.id,
          challengeId: challenge.id,
          code: code,
        );
        await supabase.auth.mfa.unenroll(totpFactors.first.id);
      }

      await supabase
          .from('profiles')
          .update({'mfa_enabled': false})
          .eq('id', user.id);

      if (mounted) setState(() => _mfaEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Two-factor authentication disabled')),
      );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to disable MFA: $e')),
      );
      }
      await _loadMfaState();
    } finally {
      if (mounted) setState(() => _loadingMfa = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await supabase.auth.signOut();

    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0.5,
        leading: const BackButton(),
        title: Text(
          'Settings',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _sectionHeader('Account'),

                _tile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen())),
                ),
                _tile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen())),
                ),
                _tile(
                  icon: Icons.bookmark_border,
                  title: 'Saved Posts',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const SavedPostsScreen())),
                ),

                const SizedBox(height: 8),
                _sectionHeader('Appearance'),

                _switchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  value: widget.isDarkMode,
                  onChanged: (_) => widget.toggleTheme(),
                ),

                const SizedBox(height: 8),
                _sectionHeader('Privacy & Security'),

                _tile(
                  icon: Icons.shield_outlined,
                  title: 'Account Privacy',
                  subtitle: 'Control who can see your profile',
                  onTap: () {},
                ),
                _tile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage your notification preferences',
                  onTap: () {},
                ),

                const SizedBox(height: 8),
                _sectionHeader('Security'),

                SwitchListTile(
                  secondary: const Icon(Icons.verified_user_outlined),
                  title: const Text('Two-Factor Authentication'),
                  subtitle: Text(
                    _mfaEnabled
                        ? 'Your account has extra protection'
                        : 'Add an extra layer of security',
                  ),
                  value: _mfaEnabled,
                  onChanged: _loadingMfa ? null : _toggleMfa,
                ),

                if (_loadingMfa)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: LinearProgressIndicator(),
                  ),

                const SizedBox(height: 8),
                _sectionHeader('Login'),

                _tile(
                  icon: Icons.person_add_outlined,
                  title: 'Add Another Account',
                  onTap: () {},
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton(
                    onPressed: () => _logout(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
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

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}