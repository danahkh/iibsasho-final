import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constant/app_color.dart';
import '../../core/services/password_reset_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: _emailSent ? _buildEmailSentView() : _buildEmailInputView(),
      ),
    );
  }

  Widget _buildEmailInputView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Icon(
            Icons.lock_reset,
            size: 80,
            color: AppColor.primary,
          ),
          SizedBox(height: 30),
          Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColor.textDark,
            ),
          ),
          SizedBox(height: 15),
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: TextStyle(
              fontSize: 16,
              color: AppColor.textDark.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 30),
          
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email, color: AppColor.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColor.primary, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          SizedBox(height: 30),
          
          // Send Reset Email Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: AppColor.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: AppColor.textOnPrimary)
                  : Text(
                      'Send Reset Email',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Back to Sign In
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Back to Sign In',
                style: TextStyle(
                  color: AppColor.primary,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSentView() {
    return Column(
      children: [
        SizedBox(height: 50),
        Icon(
          Icons.mark_email_read,
          size: 100,
          color: Colors.green,
        ),
        SizedBox(height: 30),
        Text(
          'Email Sent!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColor.textDark,
          ),
        ),
        SizedBox(height: 15),
        Text(
          'Check your email for a password reset link.',
          style: TextStyle(
            fontSize: 16,
            color: AppColor.textDark.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        Text(
          _emailController.text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColor.primary,
          ),
        ),
        SizedBox(height: 40),
        
        // Resend Email Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _sendResetEmail,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColor.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? CircularProgressIndicator(color: AppColor.primary)
                : Text(
                    'Resend Email',
                    style: TextStyle(
                      color: AppColor.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        
        SizedBox(height: 20),
        
        // Back to Sign In
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Back to Sign In',
            style: TextStyle(
              color: AppColor.primary,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendResetEmail() async {
    if (!_emailSent && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
  await PasswordResetService.sendResetEmail(_emailController.text.trim());

      if (mounted) {
        setState(() {
          _emailSent = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset email sent successfully. Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthException catch (e) {
      String errorMessage;
      if (e.message.contains('Invalid email')) {
        errorMessage = 'Please enter a valid email address';
      } else if (e.message.contains('too many')) {
        errorMessage = 'Too many reset requests. Please try again later.';
      } else {
        errorMessage = 'Failed to send reset email. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
