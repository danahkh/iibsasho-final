import 'package:supabase_flutter/supabase_flutter.dart';

/// Password reset (email-based) service.
///
/// Flow:
/// 1. Call [sendResetEmail] with user email. A magic link is emailed.
/// 2. User taps the link -> app is opened via deep link (configure a redirect URL
///    in Supabase Auth Settings pointing to the scheme below).
/// 3. Supabase emits an `AuthChangeEvent.passwordRecovery` event which is
///    listened to in `main.dart` and navigates to `PasswordResetPage` UI.
/// 4. User enters a new password; we call `updateUser` to complete.
///
/// NOTE: You must add the deep link (e.g. io.supabase.flutter://reset-callback)
/// to: Supabase Dashboard > Authentication > URL Configuration > Redirect URLs.
class PasswordResetService {
  static final _client = Supabase.instance.client;

  // Update if you change the scheme/host you register in Supabase dashboard.
  static const String redirectDeepLink = 'io.supabase.flutter://reset-callback';

  static Future<void> sendResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectDeepLink,
    );
  }

  /// Update password for the currently recovering user.
  static Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
