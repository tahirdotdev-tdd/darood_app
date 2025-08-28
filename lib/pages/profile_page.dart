// lib/screens/profile_page.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:darood_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // To access the global 'supabase' client

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getProfile(); // Fetch profile data when the screen loads
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  // Fetches the current user's profile from the 'profiles' table
  Future<void> _getProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase.from('profiles').select().eq('id', userId).single();

      _usernameController.text = data['username'] ?? '';
      _fullNameController.text = data['full_name'] ?? '';
      _avatarUrl = data['avatar_url'];

    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profile: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Updates the user's profile in the 'profiles' table
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    final userName = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    final userId = supabase.auth.currentUser!.id;

    try {
      await supabase.from('profiles').update({
        'username': userName,
        'full_name': fullName,
      }).eq('id', userId);

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!'))
        );
      }
    } catch(error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Picks an image, uploads it to Supabase Storage, and updates the avatar URL
  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
    );

    if (imageFile == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final userId = supabase.auth.currentUser!.id;
      // The path where the image will be stored in the 'avatars' bucket
      final filePath = '$userId/$fileName';

      // Upload image to Supabase Storage
      await supabase.storage.from('avatars').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(contentType: imageFile.mimeType),
      );

      // Get the public URL of the uploaded image
      final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);

      // Update the user's avatar_url in the profiles table
      await supabase.from('profiles').update({'avatar_url': imageUrl}).eq('id', userId);

      if(mounted) {
        setState(() {
          _avatarUrl = imageUrl;
        });
      }

    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading avatar: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Avatar Section
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null ? const Icon(Icons.person, size: 60) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    onPressed: _uploadAvatar,
                    icon: const Icon(Icons.camera_alt),
                    style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Form Fields
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          const SizedBox(height: 24),
          // Update Button
          ElevatedButton(
            onPressed: _updateProfile,
            child: const Text('Save Changes'),
          ),
          const SizedBox(height: 16),
          // Sign Out Button
          TextButton(
            onPressed: () => supabase.auth.signOut(),
            child: const Text('Sign Out'),
          )
        ],
      ),
    );
  }
}