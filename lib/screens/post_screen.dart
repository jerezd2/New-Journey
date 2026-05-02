import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:supabase_app/theme/app_spacing.dart';
import 'package:supabase_app/widgets/app_button.dart';
import 'package:supabase_app/widgets/app_screen.dart';
import 'package:supabase_app/widgets/app_text_field.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _submitPost() async {
    if (_nameController.text.isEmpty ||
        _categoryController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and select an image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      final Uint8List fileBytes = await _imageFile!.readAsBytes();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(_imageFile!.path)}';

      await supabase.storage
          .from('place-images')
          .uploadBinary(fileName, fileBytes);

      final imageUrl =
          supabase.storage.from('place-images').getPublicUrl(fileName);

      await supabase.from('places').insert({
        'user_id': user!.id,
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error creating post: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Add New Place',
      child: SingleChildScrollView(
        child: Column(
          children: [
            AppTextField(controller: _nameController, label: 'Place Name'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(controller: _categoryController, label: 'Category'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 4),
            const SizedBox(height: AppSpacing.lg),
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_imageFile!, height: 180),
              )
            else
              const Text('No image selected'),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
                onPressed: _pickImage, child: const Text('Pick Image')),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
                label: 'Submit',
                onPressed: _submitPost,
                loading: _isLoading),
          ],
        ),
      ),
    );
  }
}