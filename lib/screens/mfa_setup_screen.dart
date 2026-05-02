import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MfaSetupScreen extends StatefulWidget {
  final String factorId;
  final String secret;

  final Future<void> Function()? onVerified;

  const MfaSetupScreen({
    super.key,
    required this.factorId,
    required this.secret,
    this.onVerified,
  });

  @override
  State<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends State<MfaSetupScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController codeController = TextEditingController();

  bool loading = false;

  Future<void> _copySecret() async {
    await Clipboard.setData(ClipboardData(text: widget.secret));
    _snack('Secret copied to clipboard');
  }

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      codeController.text = data!.text!.trim();
    }
  }

  Future<void> verify() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      _snack('Enter the 6-digit code');
      return;
    }

    setState(() => loading = true);

    try {
      //mfa challenge
      final challenge = await supabase.auth.mfa.challenge(
        factorId: widget.factorId,
      );

      //verify code
      await supabase.auth.mfa.verify(
        factorId: widget.factorId,
        challengeId: challenge.id,
        code: code,
      );

      //run onVerified callback if provided
      if (widget.onVerified != null) {
        await widget.onVerified!();
      }

      if (!mounted) return;

      //back to AuthGate
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('MFA setup failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up 2FA'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            const Icon(Icons.security, size: 70),

            const SizedBox(height: 20),

            const Text(
              'Enter this secret in Google Authenticator',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      widget.secret,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _copySecret,
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy secret',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Enter 6-digit code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  onPressed: _pasteCode,
                  icon: const Icon(Icons.content_paste, size: 20),
                  tooltip: 'Paste code',
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : verify,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify & Enable'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}