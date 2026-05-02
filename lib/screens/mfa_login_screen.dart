import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MfaLoginScreen extends StatefulWidget {
  final String factorId;

  const MfaLoginScreen({
    super.key,
    required this.factorId,
  });

  @override
  State<MfaLoginScreen> createState() => _MfaLoginScreenState();
}

class _MfaLoginScreenState extends State<MfaLoginScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController codeController = TextEditingController();

  bool loading = false;

  Future<void> verify() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      _snack('Enter your authentication code');
      return;
    }

    setState(() => loading = true);

    try {
      final challenge = await supabase.auth.mfa.challenge(
        factorId: widget.factorId,
      );

      await supabase.auth.mfa.verify(
        factorId: widget.factorId,
        challengeId: challenge.id,
        code: code,
      );

      //authgate listens to challenge and will shows nav screen.
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Verification failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        centerTitle: true,
        automaticallyImplyLeading: false, //no back button on MFA screen
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.lock_outline,
              size: 70,
              color: Colors.black87,
            ),

            const SizedBox(height: 20),

            const Text(
              'Enter your authentication code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Open your authenticator app and enter the 6-digit code',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: '6-digit code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : verify,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.black,
                ),
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verify',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}