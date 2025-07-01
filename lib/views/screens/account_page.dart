import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../constant/app_color.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  User? user;
  Map<String, dynamic>? userData;
  bool _loading = true;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    setState(() {
      userData = doc.data();
      _loading = false;
    });
  }

  Future<void> _changePassword() async {
    // You can use showDialog to prompt for new password
    String? newPassword;
    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Change Password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(hintText: 'New Password'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                newPassword = controller.text;
                Navigator.of(context).pop();
              },
              child: Text('Change'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
    if (newPassword != null && newPassword!.isNotEmpty) {
      await user?.updatePassword(newPassword!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password updated.')));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
      // TODO: Upload to storage and update Firestore user photoUrl
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Account'), backgroundColor: Colors.transparent, elevation: 0),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Account'), backgroundColor: Colors.transparent, elevation: 0),
        body: Center(child: Text('No user data found.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(
              height: 32,
              width: 32,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.asset('assets/icons/iibsashologo.svg', package: null),
              ),
            ),
            Text('Account'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (userData!['photoUrl'] != null && userData!['photoUrl'] != ''
                          ? NetworkImage(userData!['photoUrl'])
                          : null) as ImageProvider<Object>?,
                  child: _imageFile == null && (userData!['photoUrl'] == null || userData!['photoUrl'] == '')
                      ? Icon(Icons.person, size: 40)
                      : null,
                ),
              ),
            ),
            SizedBox(height: 24),
            Text('Name: ${userData!['name'] ?? ''}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Email: ${userData!['email'] ?? ''}', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _changePassword,
              child: Text('Change Password'),
            ),
            SizedBox(height: 8),
            Text('Tap the avatar to change your image.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
