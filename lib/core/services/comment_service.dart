import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/comment.dart';
import '../utils/app_logger.dart';

class CommentService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Add a comment to a listing
  static Future<Comment?> addComment({
    required String listingId,
    required String text,
    String? parentId,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      // Fetch optional user profile fields
      String userName = 'Anonymous';
      String userPhotoUrl = '';
      try {
        final userResponse = await _supabase
            .from('users')
            .select('name, display_name, photo_url')
            .eq('id', currentUser.id)
            .maybeSingle();
        if (userResponse != null) {
          // Prefer display_name if present
            userName = userResponse['display_name'] ?? userResponse['name'] ?? 'Anonymous';
            userPhotoUrl = userResponse['photo_url'] ?? '';
        }
      } catch (_) {}

      // Build base payload WITHOUT id so DB (uuid default) assigns one
      final nowIso = DateTime.now().toIso8601String();
      Map<String, dynamic> payload = {
        'listing_id': listingId,
        'user_id': currentUser.id,
        'content': text.trim(),
        'parent_id': parentId,
        'user_name': userName, // may not exist in schema
        'user_photo_url': userPhotoUrl, // may not exist
        'created_at': nowIso,
      };

      Map<String, dynamic>? inserted;
      // Attempt with full payload
      try {
        inserted = await _supabase.from('comments').insert(payload).select().single();
      } catch (e) {
        final msg = e.toString();
        // Remove optional columns that might not exist
        if (msg.contains('user_name') || msg.contains('user_photo_url')) {
          payload.remove('user_name');
          payload.remove('user_photo_url');
          try {
            inserted = await _supabase.from('comments').insert(payload).select().single();
          } catch (e2) {
            // Continue to minimal fallback
          }
        }
        if (inserted == null) {
          // Minimal fallback: only required fields
            final minimal = {
              'listing_id': listingId,
              'user_id': currentUser.id,
              'content': text.trim(),
              'created_at': nowIso,
              'parent_id': parentId,
            };
            try {
              inserted = await _supabase.from('comments').insert(minimal).select().single();
            } catch (e3) {
              AppLogger.e('addComment all fallbacks failed', e3);
              return null;
            }
        }
      }

      return Comment.fromJson(inserted);
    } catch (e) {
      AppLogger.e('addComment failed', e);
      return null;
    }
  }

  // Like a comment (insert into comment_likes, increment count if you keep a counter column)
  static Future<bool> likeComment(String commentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      await _supabase.from('comment_likes').insert({
        'comment_id': commentId,
        'user_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      // Ignore unique violation
      if (!e.toString().contains('duplicate')) {
        AppLogger.e('likeComment failed', e);
      }
      return false;
    }
  }

  static Future<bool> unlikeComment(String commentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      await _supabase.from('comment_likes')
          .delete()
          .eq('comment_id', commentId)
          .eq('user_id', user.id);
      return true;
    } catch (e) {
      AppLogger.e('unlikeComment failed', e);
      return false;
    }
  }

  static Future<List<String>> getUserLikedCommentIds(String listingId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];
      final data = await _supabase
          .from('comment_likes')
          .select('comment_id')
          .eq('user_id', user.id);
      return List<String>.from(data.map((r) => r['comment_id'].toString()));
    } catch (e) {
      return [];
    }
  }

  // Fetch replies for a comment
  static Future<List<Comment>> getReplies(String parentCommentId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select()
          .eq('parent_id', parentCommentId)
          .order('created_at', ascending: true);
      return response.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      AppLogger.e('getReplies failed', e);
      return [];
    }
  }

  // Get comments for a listing
  static Future<List<Comment>> getComments(String listingId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select()
          .eq('listing_id', listingId)
          .order('created_at', ascending: false);
      // Always enrich all comments with user display_name/photo for consistency
      final userIds = response
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      Map<String, Map<String, dynamic>> userMap = {};
      if (userIds.isNotEmpty) {
        try {
          final fetched = await _supabase
              .from('users')
              .select('id, name, display_name, photo_url')
              .inFilter('id', userIds);
          for (final u in fetched) {
            userMap[u['id']] = u;
          }
        } catch (_) {}
      }
      return response.map((r) {
        final u = userMap[r['user_id']];
        if (u != null) {
          final copy = Map<String, dynamic>.from(r);
          copy['users'] = u; // leveraged by model
          return Comment.fromJson(copy);
        }
        return Comment.fromJson(r);
      }).toList();
    } catch (e) {
      AppLogger.e('getComments failed', e);
      return [];
    }
  }

  // Delete a comment (only by the comment author)
  static Future<bool> deleteComment(String commentId, String userId) async {
    try {
      await _supabase
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      AppLogger.e('deleteComment failed', e);
      return false;
    }
  }

  // Update (edit) a comment content if owned by user
  static Future<bool> updateComment({required String commentId, required String userId, required String newContent}) async {
    try {
      final trimmed = newContent.trim();
      if (trimmed.isEmpty) throw Exception('Empty');
      await _supabase
          .from('comments')
          .update({'content': trimmed, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', commentId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      AppLogger.e('updateComment failed', e);
      return false;
    }
  }

  // Stream comments for real-time updates
  static Stream<List<Comment>> getCommentsStream(String listingId) {
    // Real-time stream (without join, Supabase Realtime currently doesn't support join directly),
    // we'll post-process and fetch user names if missing.
    return _supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('listing_id', listingId)
        .order('created_at', ascending: false)
        .asyncMap((rows) async {
          // Identify any user_ids with missing user_name to fill
          final missing = rows
              .where((r) => (r['user_name'] == null || (r['user_name'] as String?)?.isEmpty == true))
              .map((r) => r['user_id'] as String?)
              .whereType<String>()
              .toSet();
          Map<String, Map<String, dynamic>> userMap = {};
          if (missing.isNotEmpty) {
            try {
              final fetched = await _supabase
                  .from('users')
                  .select('id, name, display_name, photo_url')
                  .inFilter('id', missing.toList());
              for (final u in fetched) {
                userMap[u['id']] = u;
              }
            } catch (_) {}
          }
          final enriched = rows.map((r) {
            if ((r['user_name'] == null || (r['user_name'] as String?)?.isEmpty == true)) {
              final u = userMap[r['user_id']];
              if (u != null) {
                r = Map<String, dynamic>.from(r);
                r['users'] = u; // so Comment.fromJson can extract
              }
            }
            return Comment.fromJson(r);
          }).toList();
          return enriched;
        });
  }
}
