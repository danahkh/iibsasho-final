import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constant/app_color.dart';
import '../../core/services/password_reset_service.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;
  bool _success = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await PasswordResetService.updatePassword(_passwordController.text.trim());
      if (mounted) {
        setState(() => _success = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully'), backgroundColor: Colors.green),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update password'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: AppColor.primary,
        foregroundColor: AppColor.textOnPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _success ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Icon(Icons.lock_reset, size: 72, color: AppColor.primary),
          const SizedBox(height: 24),
          Text('Create a new password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColor.textDark)),
          const SizedBox(height: 12),
          Text('Please enter and confirm your new password.', style: TextStyle(fontSize: 16, color: AppColor.textDark.withOpacity(0.7))),
          const SizedBox(height: 28),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: Icon(Icons.lock_outline, color: AppColor.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a password';
              if (v.length < 8) return 'Minimum 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock, color: AppColor.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm password';
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: AppColor.textOnPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _submitting
                  ? CircularProgressIndicator(color: AppColor.textOnPrimary)
                  : const Text('Update Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 96),
        const SizedBox(height: 24),
        Text('Password Updated', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColor.textDark)),
        const SizedBox(height: 12),
        Text('You can now sign in with your new password.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColor.textDark.withOpacity(0.7))),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, foregroundColor: AppColor.textOnPrimary),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }
}
