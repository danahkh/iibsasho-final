import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';
import 'category_service.dart';
import 'database_service.dart';
import 'user_service.dart';

class AppInitializationService {
  static bool _isInitialized = false;

  /// Initialize the app with Supabase and required services
  static Future<bool> initializeApp() async {
    try {
      if (_isInitialized) return true;

  AppLogger.i('Initializing Supabase services...');
      
      // Initialize default categories
  AppLogger.i('Initializing default categories...');
      await CategoryService.initializeDefaultCategories();
  AppLogger.i('Default categories initialized successfully');
      
      // Set up auth state listener
      _setupAuthStateListener();
      
      _isInitialized = true;
  AppLogger.i('App initialization completed successfully');
      return true;
      
    } catch (e) {
  AppLogger.e('Error initializing app', e);
      return false;
    }
  }

  /// Set up authentication state listener
  static void _setupAuthStateListener() {
    final client = Supabase.instance.client;
    
    client.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      
      if (user != null) {
  AppLogger.i('User signed in: ${user.email}');
        
        // Create or update user profile when user signs in
  await DatabaseService.createOrUpdateUser({'display_name': user.userMetadata?['display_name'] ?? ''});
  // Capture telemetry (location + device snapshot) asynchronously
  UserService.captureTelemetry();
      } else {
  AppLogger.i('User signed out');
      }
    });
  }

  /// Check if the app is properly initialized
  static bool get isInitialized => _isInitialized;

  /// Get app status information
  static Map<String, dynamic> getAppStatus() {
    final client = Supabase.instance.client;
    return {
      'isInitialized': _isInitialized,
      'supabaseInitialized': true, // Supabase is initialized if we can access the client
      'currentUser': client.auth.currentUser?.email,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Reset initialization state (for testing)
  static void reset() {
    _isInitialized = false;
  }
}
