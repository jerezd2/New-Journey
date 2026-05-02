import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final supabase = Supabase.instance.client;

  final _firstName = TextEditingController();
  final _lastName  = TextEditingController();
  final _username  = TextEditingController();
  final _phone     = TextEditingController();

  final _address = TextEditingController();
  final _city    = TextEditingController();
  final _state   = TextEditingController();
  final _country = TextEditingController();
  final _zip     = TextEditingController();

  File? _image;
  String? _existingAvatarUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user!.id)
        .single();

    _firstName.text       = data['first_name'] ?? '';
    _lastName.text        = data['last_name'] ?? '';
    _username.text        = data['username'] ?? '';
    _phone.text           = data['phone'] ?? '';
    _address.text         = data['address'] ?? '';
    _city.text            = data['city'] ?? '';
    _state.text           = data['state'] ?? '';
    _country.text         = data['country'] ?? '';
    _zip.text             = data['zip_code'] ?? '';
    _existingAvatarUrl    = data['avatar_url'] as String?;

    setState(() {});
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    try {
      final user = supabase.auth.currentUser;

      String? avatarUrl;
      if (_image != null) {
        final bytes    = await _image!.readAsBytes();
        final fileName = '${user!.id}.jpg';
        await supabase.storage.from('avatars').uploadBinary(fileName, bytes,
            fileOptions: const FileOptions(upsert: true));
        avatarUrl =
            supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      final updates = <String, dynamic>{
        'first_name': _firstName.text.trim(),
        'last_name':  _lastName.text.trim(),
        'username':   _username.text.trim(),
        'phone':      _phone.text.trim(),
        'address':    _address.text.trim(),
        'city':       _city.text.trim(),
        'state':      _state.text.trim(),
        'country':    _country.text.trim(),
        'zip_code':   _zip.text.trim(),
      };

      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await supabase
          .from('profiles')
          .update(updates)
          .eq('id', user!.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayImage = _image != null
        ? FileImage(_image!) as ImageProvider
        : (_existingAvatarUrl != null
            ? NetworkImage(_existingAvatarUrl!) as ImageProvider
            : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 45,
                backgroundImage: displayImage,
                child: displayImage == null
                    ? const Icon(Icons.camera_alt)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            _field(_firstName, 'First Name'),
            _field(_lastName, 'Last Name'),
            _field(_username, 'Username'),
            _field(_phone, 'Phone'),
            _field(_address, 'Address'),
            _field(_city, 'City'),
            _field(_state, 'State'),
            _field(_country, 'Country'),
            _field(_zip, 'Zip Code'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _saveProfile,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _country.dispose();
    _zip.dispose();
    super.dispose();
  }
}