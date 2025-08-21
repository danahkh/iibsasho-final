class SupabaseConfig {
  // Supabase project credentials
  static const String supabaseUrl = 'https://lvvlhybntvxmohairkpi.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2dmxoeWJudHZ4bW9oYWlya3BpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNjI1MTAsImV4cCI6MjA2ODgzODUxMH0.z-3Kd-F2uqhMhWV4el5Z8Y_4n_tlTCkQdiOrMkYTjVM';
  
  // Database table names
  static const String usersTable = 'users';
  static const String listingsTable = 'listings';
  static const String supportRequestsTable = 'support_requests';
  static const String promotionRequestsTable = 'promotion_requests';
  static const String favoritesTable = 'favorites';
  static const String messagesTable = 'messages';
  static const String chatsTable = 'chats';
  static const String notificationsTable = 'notifications';
  static const String reportsTable = 'reports';
  static const String featuredListingsTable = 'featured_listings';
  
  // Configuration flags - PURE SUPABASE SETUP
  static const bool useSupabaseForDatabase = true;
  static const bool useSupabaseForAuth = true;
  static const bool useSupabaseForStorage = true;
}
