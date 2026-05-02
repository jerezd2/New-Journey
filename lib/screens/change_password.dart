import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final supabase = Supabase.instance.client;

  final _oldPasswordController     = TextEditingController();
  final _newPasswordController     = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _oldVisible     = false;
  bool _newVisible     = false;
  bool _confirmVisible = false;
  bool _loading        = false;
  bool _oldVerified    = false;
  bool _verifying      = false;

  static const _kOrange  = Color(0xFFE8640A);
  static const _kEmerald = Color(0xFF10B981);

  Future<void> _verifyOldPassword() async {
    final oldPw = _oldPasswordController.text.trim();
    if (oldPw.isEmpty) {
      _snack('Enter your current password');
      return;
    }

    setState(() => _verifying = true);
    try {
      final user  = supabase.auth.currentUser;
      final email = user?.email ?? '';
      await supabase.auth
          .signInWithPassword(email: email, password: oldPw);
      setState(() {
        _oldVerified = true;
        _verifying   = false;
      });
      _snack('Current password verified ✓');
    } catch (_) {
      setState(() => _verifying = false);
      _snack('Current password is incorrect');
    }
  }

  Future<void> _updatePassword() async {
    if (!_oldVerified) {
      _snack('Verify your current password first');
      return;
    }

    final newPw     = _newPasswordController.text.trim();
    final confirmPw = _confirmPasswordController.text.trim();

    if (newPw.isEmpty || confirmPw.isEmpty) {
      _snack('Fill all fields');
      return;
    }
    if (newPw.length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }
    if (newPw != confirmPw) {
      _snack('New passwords do not match');
      return;
    }
    if (newPw == _oldPasswordController.text.trim()) {
      _snack('New password must be different');
      return;
    }

    setState(() => _loading = true);
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPw));
      if (!mounted) return;
      _snack('Password updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _passwordField(
    TextEditingController controller,
    String label, {
    required bool visible,
    required VoidCallback onToggle,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      enabled: enabled,
      onChanged: (_) => setState(() {}), // rebuild for match indicator
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.grey.shade100 : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kOrange, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Change Password',
          style:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

           
            _sectionLabel('STEP 1 — VERIFY CURRENT PASSWORD',
                active: true),
            const SizedBox(height: 12),

            _passwordField(
              _oldPasswordController,
              'Current Password',
              visible: _oldVisible,
              onToggle: () =>
                  setState(() => _oldVisible = !_oldVisible),
              enabled: !_oldVerified,
            ),
            const SizedBox(height: 10),

            if (!_oldVerified)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _verifyOldPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _verifying
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Verify Current Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              )
            else
            
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Current password verified',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 20),

          
            _sectionLabel('STEP 2 — SET NEW PASSWORD',
                active: _oldVerified),
            const SizedBox(height: 12),

            _passwordField(
              _newPasswordController,
              'New Password',
              visible: _newVisible,
              onToggle: () =>
                  setState(() => _newVisible = !_newVisible),
              enabled: _oldVerified,
            ),
            const SizedBox(height: 12),

            _passwordField(
              _confirmPasswordController,
              'Confirm New Password',
              visible: _confirmVisible,
              onToggle: () =>
                  setState(() => _confirmVisible = !_confirmVisible),
              enabled: _oldVerified,
            ),

         
            if (_confirmPasswordController.text.isNotEmpty &&
                _oldVerified) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _newPasswordController.text ==
                          _confirmPasswordController.text
                      ? '✓ Passwords match'
                      : '✗ Passwords do not match',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _newPasswordController.text ==
                            _confirmPasswordController.text
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_loading || !_oldVerified) ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kEmerald,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Update Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, {required bool active}) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        color: active ? Colors.grey.shade500 : Colors.grey.shade300,
        letterSpacing: 1.0,
      ),
    );
  }
}