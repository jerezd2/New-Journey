import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

const _kOrange      = Color(0xFFE8640A);
const _kEmerald     = Color(0xFF10B981);
const _kOrangeLight = Color(0xFFFFF3EC);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final supabase = Supabase.instance.client;

  final _loginIdentifierController = TextEditingController();
  final _loginPasswordController   = TextEditingController();
  bool _loginPasswordVisible = false;

  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _emailController     = TextEditingController();
  final _phoneController     = TextEditingController();
  final _dobController       = TextEditingController();

  final _addressController = TextEditingController();
  final _aptController     = TextEditingController();
  final _cityController    = TextEditingController();
  final _stateController   = TextEditingController();
  final _zipController     = TextEditingController();
  final _countryController = TextEditingController();

  List<dynamic> _addressResults  = [];
  bool          _isSearchingAddr = false;
  Timer?        _addrDebounce;

  final _usernameController        = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible        = false;
  bool _confirmPasswordVisible = false;

  bool   _usernameAvailable   = false;
  bool   _checkingUsername    = false;
  String _lastCheckedUsername = '';
  Timer? _usernameDebounce;
  List<String> _suggestions  = [];

  File? _profileImage;

  bool _isLogin = true;
  bool _loading = false;
  int  _step    = 0;

  final _forgotEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _usernameController.addListener(() {
      final u = _usernameController.text.trim();
      if (_usernameDebounce?.isActive ?? false) _usernameDebounce!.cancel();
      _usernameDebounce =
          Timer(const Duration(milliseconds: 500), () => _checkUsername(u));
    });

    _addressController.addListener(() {
      final q = _addressController.text.trim();
      if (_addrDebounce?.isActive ?? false) _addrDebounce!.cancel();
      _addrDebounce =
          Timer(const Duration(milliseconds: 600), () => _searchAddress(q));
    });
  }
//auto fill address

  Future<void> _searchAddress(String query) async {
    if (query.length < 3) {
      setState(() => _addressResults = []);
      return;
    }
    setState(() => _isSearchingAddr = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=6',
      );
      final res = await http.get(url, headers: {'User-Agent': 'new_journey_app'});
      if (res.statusCode == 200) {
        setState(() {
          _addressResults  = jsonDecode(res.body);
          _isSearchingAddr = false;
        });
      } else {
        setState(() => _isSearchingAddr = false);
      }
    } catch (_) {
      setState(() => _isSearchingAddr = false);
    }
  }

  void _selectAddress(dynamic place) {
    final addr = place['address'] ?? {};
    _addrDebounce?.cancel();
    setState(() {
      _addressController.text = place['display_name'] ?? '';
      _cityController.text    = addr['city'] ?? addr['town'] ?? addr['village'] ?? '';
      _stateController.text   = addr['state'] ?? '';
      _countryController.text = addr['country'] ?? '';
      _zipController.text     = addr['postcode'] ?? '';
      _addressResults         = [];
    });
  }

  Future<void> _checkUsername(String username) async {
    if (username.isEmpty) return;
    setState(() => _checkingUsername = true);
    try {
      final res = await supabase
          .from('profiles')
          .select('username')
          .ilike('username', username)
          .limit(1);
      final available = (res as List).isEmpty;
      setState(() {
        _usernameAvailable   = available;
        _checkingUsername    = false;
        _lastCheckedUsername = username;
        _suggestions = available ? [] : _makeSuggestions(username);
      });
    } catch (_) {
      setState(() => _checkingUsername = false);
    }
  }

  List<String> _makeSuggestions(String u) {
    final base = u.toLowerCase().replaceAll(' ', '');
    return [
      '${base}123',
      '${base}_${DateTime.now().year}',
      '$base.explorer',
      '$base${DateTime.now().millisecondsSinceEpoch % 999}',
    ];
  }

  Future<void> _login() async {
    final identifier = _loginIdentifierController.text.trim();
    final password   = _loginPasswordController.text.trim();
    if (identifier.isEmpty || password.isEmpty) {
      _snack('Please fill in all fields');
      return;
    }
    setState(() => _loading = true);
    try {
      String emailToUse = identifier;

      if (!identifier.contains('@')) {
        final profileRes = await supabase
            .from('profiles')
            .select('email')
            .ilike('username', identifier)
            .limit(1)
            .maybeSingle();

        final found = profileRes?['email'] as String?;
        if (found == null || found.isEmpty) {
          _snack('No account found for that username');
          setState(() => _loading = false);
          return;
        }
        emailToUse = found;
      }

      await supabase.auth.signInWithPassword(email: emailToUse, password: password);
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForgotPassword() {
    _forgotEmailController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Enter the email linked to your account and we'll send a reset link."),
            const SizedBox(height: 16),
            _field(_forgotEmailController, 'Email',
                keyboardType: TextInputType.emailAddress),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOrange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final email = _forgotEmailController.text.trim();
              if (email.isEmpty) { _snack('Enter your email'); return; }
              Navigator.pop(ctx);
              try {
                await supabase.auth.resetPasswordForEmail(email);
                _snack('Reset link sent! Check your email.');
              } catch (e) {
                _snack(e.toString());
              }
            },
            child: const Text('Send Link',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  Future<void> _completeSignup() async {
    if (!_usernameAvailable) {
      _snack('Choose an available username');
      return;
    }
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      _snack('Passwords do not match');
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }
    setState(() => _loading = true);
    try {
      final email    = _emailController.text.trim();
      final password = _passwordController.text.trim();

      await supabase.auth.signUp(email: email, password: password);

      final loginRes = await supabase.auth
          .signInWithPassword(email: email, password: password);
      final user = loginRes.user;
      if (user == null) {
        _snack('Signup failed. Please try again.');
        return;
      }

      String? avatarUrl;
      if (_profileImage != null) {
        final bytes    = await _profileImage!.readAsBytes();
        final fileName = '${user.id}.jpg';
        await supabase.storage.from('avatars').uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
        avatarUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      final profileData = <String, dynamic>{
        'id':         user.id,
        'email':      email,
        'first_name': _firstNameController.text.trim(),
        'last_name':  _lastNameController.text.trim(),
        'username':   _usernameController.text.trim(),
        'phone':      _phoneController.text.trim(),
        'date_of_birth': _dobController.text.trim(),
      };

      if (_addressController.text.trim().isNotEmpty)
        profileData['address'] = _addressController.text.trim();
      if (_aptController.text.trim().isNotEmpty)
        profileData['apartment_number'] = _aptController.text.trim();
      if (_cityController.text.trim().isNotEmpty)
        profileData['city'] = _cityController.text.trim();
      if (_stateController.text.trim().isNotEmpty)
        profileData['state'] = _stateController.text.trim();
      if (_zipController.text.trim().isNotEmpty)
        profileData['zip_code'] = _zipController.text.trim();
      if (_countryController.text.trim().isNotEmpty)
        profileData['country'] = _countryController.text.trim();
      if (avatarUrl != null)
        profileData['avatar_url'] = avatarUrl;

      await supabase.from('profiles').upsert(profileData);
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

  bool _canAdvanceStep0() =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty;

 
  bool _canAdvanceStep1() => true;

  bool _canAdvanceStep2() =>
      _usernameAvailable &&
      _passwordController.text.trim().length >= 6 &&
      _passwordController.text.trim() ==
          _confirmPasswordController.text.trim();

  Widget _field(
    TextEditingController c,
    String label, {
    bool obscure = false,
    bool? showText,
    VoidCallback? toggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        obscureText: obscure && !(showText ?? false),
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade100,
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
          suffixIcon: toggleVisibility != null
              ? IconButton(
                  icon: Icon(
                    (showText ?? false)
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
        ),
      ),
    );
  }

  Widget _stepIndicator(int total, int current) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == current ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == current ? _kOrange : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildLoginScreen() {
    return Scaffold(
      backgroundColor: _kOrange,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        'New Journey',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Discover your next adventure',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/brown-bear-logo.png',
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in with your email or username',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                      ),
                      const SizedBox(height: 22),

                      _field(
                        _loginIdentifierController,
                        'Email or Username',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _field(
                        _loginPasswordController,
                        'Password',
                        obscure: true,
                        showText: _loginPasswordVisible,
                        toggleVisibility: () => setState(() =>
                            _loginPasswordVisible = !_loginPasswordVisible),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPassword,
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                                color: _kOrange,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kEmerald,
                            padding:
                                const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account?",
                              style:
                                  TextStyle(color: Colors.grey.shade600)),
                          TextButton(
                            onPressed: () => setState(
                                () { _isLogin = false; _step = 0; }),
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _kOrange),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepIndicator(4, 0),
        const SizedBox(height: 24),
        const Text("What's your name?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Fill in your personal information',
            style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _field(_firstNameController, 'First Name')),
          const SizedBox(width: 10),
          Expanded(child: _field(_lastNameController, 'Last Name')),
        ]),
        _field(_emailController, 'Email Address',
            keyboardType: TextInputType.emailAddress),
        _field(_phoneController, 'Phone Number',
            keyboardType: TextInputType.phone),
        _field(_dobController, 'Date of Birth', hint: 'MM/DD/YYYY'),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (!_canAdvanceStep0()) {
                _snack('Please fill in all required fields');
                return;
              }
              setState(() => _step = 1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOrange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Next',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepIndicator(4, 1),
        const SizedBox(height: 24),
        const Text('Where are you based?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          'Location is optional — you can skip this step',
          style: TextStyle(color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _kOrangeLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline, size: 14, color: _kOrange),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Start typing your address and select a suggestion — zip code will auto-fill.',
                  style: TextStyle(fontSize: 12, color: _kOrange),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _field(_addressController, 'Street Address (optional)',
            hint: 'Start typing to search...'),
        if (_isSearchingAddr)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(color: _kOrange),
          ),
        if (_addressResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                    blurRadius: 8,
                    color: Colors.black.withOpacity(0.08))
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _addressResults.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (_, i) {
                final place = _addressResults[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on,
                      color: _kOrange, size: 18),
                  title: Text(place['display_name'],
                      style: const TextStyle(fontSize: 13)),
                  onTap: () => _selectAddress(place),
                );
              },
            ),
          ),
        _field(_aptController, 'Apt / Suite (optional)'),
        Row(children: [
          Expanded(child: _field(_cityController, 'City (optional)')),
          const SizedBox(width: 10),
          Expanded(child: _field(_stateController, 'State (optional)')),
        ]),
        Row(children: [
          Expanded(
              child: _field(_zipController, 'Zip Code (optional)',
                  keyboardType: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: _field(_countryController, 'Country (optional)')),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _step = 0),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back',
                  style: TextStyle(color: Colors.black)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 2),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Next',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        // Skip option
        Center(
          child: TextButton(
            onPressed: () => setState(() => _step = 2),
            child: Text('Skip location',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepIndicator(4, 2),
        const SizedBox(height: 24),
        const Text('Create your account',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Choose a username and password',
            style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: _kOrange, width: 1.5)),
              suffixIcon: _checkingUsername
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : _lastCheckedUsername ==
                              _usernameController.text.trim() &&
                          _lastCheckedUsername.isNotEmpty
                      ? Icon(
                          _usernameAvailable
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _usernameAvailable
                              ? Colors.green
                              : Colors.red)
                      : null,
            ),
          ),
        ),
        if (_lastCheckedUsername == _usernameController.text.trim() &&
            _lastCheckedUsername.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Text(
              _usernameAvailable ? 'Username available' : 'Username taken',
              style: TextStyle(
                  fontSize: 12,
                  color:
                      _usernameAvailable ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500),
            ),
          ),
          if (!_usernameAvailable && _suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                children: _suggestions
                    .map((s) => GestureDetector(
                          onTap: () {
                            _usernameController.text = s;
                            _checkUsername(s);
                          },
                          child: Chip(
                            label: Text(s,
                                style: const TextStyle(fontSize: 12)),
                            backgroundColor: _kOrangeLight,
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
        const SizedBox(height: 8),
        _field(
          _passwordController,
          'Password',
          obscure: true,
          showText: _passwordVisible,
          toggleVisibility: () =>
              setState(() => _passwordVisible = !_passwordVisible),
        ),
        _field(
          _confirmPasswordController,
          'Confirm Password',
          obscure: true,
          showText: _confirmPasswordVisible,
          toggleVisibility: () => setState(
              () => _confirmPasswordVisible = !_confirmPasswordVisible),
        ),
        if (_confirmPasswordController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              _passwordController.text == _confirmPasswordController.text
                  ? 'Passwords match ✓'
                  : 'Passwords do not match',
              style: TextStyle(
                fontSize: 12,
                color: _passwordController.text ==
                        _confirmPasswordController.text
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _step = 1),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back',
                  style: TextStyle(color: Colors.black)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (!_canAdvanceStep2()) {
                  _snack('Check username and matching passwords');
                  return;
                }
                setState(() => _step = 3);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Next',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildSignupStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _stepIndicator(4, 3),
        const SizedBox(height: 24),
        const Text('Add a profile photo',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Show the world the explorer behind the adventures',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () async {
            final picked = await ImagePicker()
                .pickImage(source: ImageSource.gallery, imageQuality: 80);
            if (picked != null) {
              setState(() => _profileImage = File(picked.path));
            }
          },
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : null,
                child: _profileImage == null
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: _kOrange, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt,
                      size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () async {
            final picked = await ImagePicker()
                .pickImage(source: ImageSource.gallery, imageQuality: 80);
            if (picked != null) {
              setState(() => _profileImage = File(picked.path));
            }
          },
          child: const Text('Select Photo',
              style: TextStyle(
                  color: _kOrange, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _completeSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kEmerald,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Create Account',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loading ? null : _completeSignup,
          child: Text('Skip for now',
              style: TextStyle(color: Colors.grey.shade600)),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => setState(() => _step = 2),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Back',
              style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  Widget _buildSignupScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_step > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () => setState(() => _step--),
                    )
                  else
                    const SizedBox(width: 48),
                  const Text('New Journey',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton(
                    onPressed: () =>
                        setState(() { _isLogin = true; _step = 0; }),
                    child: const Text('Log in',
                        style: TextStyle(color: _kOrange)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_step == 0) _buildSignupStep0(),
              if (_step == 1) _buildSignupStep1(),
              if (_step == 2) _buildSignupStep2(),
              if (_step == 3) _buildSignupStep3(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _addrDebounce?.cancel();
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _aptController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLogin ? _buildLoginScreen() : _buildSignupScreen();
  }
}