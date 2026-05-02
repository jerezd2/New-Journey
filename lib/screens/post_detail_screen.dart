import 'package:flutter/material.dart';

class PostDetailScreen extends StatelessWidget {
  final Map post;

  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(post['name'] ?? 'Post')),
      body: Column(
        children: [
          Image.network(post['image_url']),
          const SizedBox(height: 10),
          Text(post['name'] ?? ''),
          Text(post['category'] ?? ''),
        ],
      ),
    );
  }
}