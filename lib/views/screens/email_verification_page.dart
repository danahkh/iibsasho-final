import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../constant/app_color.dart';
import '../../core/utils/supabase_helper.dart';
import '../../core/utils/app_logger.dart';
import 'page_switcher.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isEmailVerified = false;
  bool _canResendEmail = false;
  Timer? _timer;
  Timer? _resendTimer; // Add separate timer for resend cooldown
  int _resendCooldown = 60; // 60 seconds cooldown

  @override
  void initState() {
    super.initState();
    _isEmailVerified = SupabaseHelper.currentUser?.emailConfirmedAt != null;
    
    if (!_isEmailVerified) {
      _sendEmailVerification();
      _startEmailVerificationTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resendTimer?.cancel(); // Cancel resend timer
    super.dispose();
  }

  Future<void> _sendEmailVerification() async {
    try {
      final user = SupabaseHelper.currentUser;
      if (user?.email != null) {
        await SupabaseHelper.client.auth.resend(
          type: OtpType.email,
          email: user!.email!,
        );
        
        if (mounted) {
          setState(() {
            _canResendEmail = false;
            _resendCooldown = 60;
          });
          _startResendCooldown();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification email sent! Please check your inbox.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending verification email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startEmailVerificationTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        // Check email verification status with Supabase
        final user = Supabase.instance.client.auth.currentUser;
        final isVerified = user?.emailConfirmedAt != null;
        
        if (isVerified) {
          setState(() {
            _isEmailVerified = true;
          });
          timer.cancel();
          _timer = null;
          
          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email verified successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Navigate after a brief delay to show the message
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const PageSwitcher()),
                );
              }
            });
          }
        }
      } catch (e) {
        AppLogger.e('Error checking email verification', e);
        // Don't auto-navigate on error
      }
    });
  }

  void _startResendCooldown() {
    _resendTimer?.cancel(); // Cancel any existing resend timer
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_resendCooldown == 0) {
        setState(() {
          _canResendEmail = true;
        });
        timer.cancel();
        _resendTimer = null;
      } else {
        setState(() {
          _resendCooldown--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text(
          'Email Verification',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email verification icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_unread_outlined,
                size: 64,
                color: AppColor.primary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              'Check Your Email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColor.textBlack,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'We\'ve sent a verification link to:\n${Supabase.instance.client.auth.currentUser?.email}',
              style: TextStyle(
                fontSize: 16,
                color: AppColor.placeholder,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColor.accent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next steps:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Check your email inbox\n'
                    '2. Click the verification link\n'
                    '3. Return to this app',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColor.placeholder,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Resend email button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canResendEmail ? _sendEmailVerification : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: AppColor.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _canResendEmail 
                    ? 'Resend Email' 
                    : 'Resend in ${_resendCooldown}s',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Manual check button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () async {
                  // Refresh user data and check verification status
                  await SupabaseHelper.client.auth.refreshSession();
                  final user = SupabaseHelper.currentUser;
                  final isVerified = user?.emailConfirmedAt != null;
                  
                  if (isVerified) {
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const PageSwitcher()),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email not verified yet. Please check your inbox.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColor.primary,
                  side: BorderSide(color: AppColor.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'I\'ve Verified My Email',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Help text
            Text(
              'Didn\'t receive the email? Check your spam folder or contact support.',
              style: TextStyle(
                fontSize: 12,
                color: AppColor.placeholder,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
