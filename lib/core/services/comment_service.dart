import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';
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
        .select('username, display_name, full_name, email, photo_url')
            .eq('id', currentUser.id)
            .maybeSingle();
        if (userResponse != null) {
            // Prefer username, then display_name, then full_name
        userName = userResponse['username'] ?? userResponse['display_name'] ?? userResponse['full_name'] ?? '';
            // If still empty, fallback to email local-part
            if ((userName.isEmpty)) {
              final email = (userResponse['email'] ?? currentUser.email ?? '').toString();
              if (email.isNotEmpty) {
                userName = email.split('@').first;
              }
            }
            userPhotoUrl = userResponse['photo_url'] ?? '';
        }
      } catch (_) {}
      // Fallback: profiles table (if exists)
      if (userName.isEmpty) {
        try {
          final prof = await _supabase
              .from('profiles')
                .select('username, display_name, full_name, name')
              .eq('id', currentUser.id)
              .maybeSingle();
          if (prof != null) {
              userName = (prof['username'] ?? prof['display_name'] ?? prof['full_name'] ?? prof['name'] ?? '').toString();
          }
        } catch (_) {}
      }
      // Final guard: try auth userMetadata first, then email local-part, then 'Anonymous'
      if (userName.isEmpty) {
        try {
          final md = currentUser.userMetadata ?? {};
          final mdName = (md['display_name'] ?? md['full_name'] ?? md['name'] ?? md['username'] ?? '').toString().trim();
          if (mdName.isNotEmpty) userName = mdName;
        } catch (_) {}
      }
      if (userName.isEmpty) {
        final email = (currentUser.email ?? '').toString();
        if (email.isNotEmpty) userName = email.split('@').first;
      }
      if (userName.isEmpty) userName = 'Anonymous';

      // Build base payload WITHOUT id so DB (uuid default) assigns one
  final nowIso = DateTime.now().toUtc().toIso8601String();
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

      final created = Comment.fromJson(inserted);

      // Notifications: comment on listing, and reply to comment
      try {
        // Fetch listing owner and title for context
    final listing = await _supabase
      .from('listings')
      .select('user_id, title')
            .eq('id', listingId)
            .maybeSingle();
    final listingOwnerId = listing?['user_id']?.toString();
        final listingTitle = (listing?['title'] ?? 'your listing').toString();

        // If this is a top-level comment and not by owner, notify owner
        if ((parentId == null || parentId.isEmpty) &&
            listingOwnerId != null && listingOwnerId.isNotEmpty &&
            listingOwnerId != currentUser.id) {
          await NotificationService.sendCommentNotification(
            listingOwnerId: listingOwnerId,
            commenterName: userName,
            listingTitle: listingTitle,
            listingId: listingId,
            commentId: created.id,
          );
        }

        // If this is a reply, notify parent comment author (not self)
        if (parentId != null && parentId.isNotEmpty) {
          final parent = await _supabase
              .from('comments')
              .select('user_id')
              .eq('id', parentId)
              .maybeSingle();
          final parentAuthorId = parent?['user_id']?.toString();
          if (parentAuthorId != null && parentAuthorId.isNotEmpty && parentAuthorId != currentUser.id) {
            await NotificationService.sendCommentReplyNotification(
              parentAuthorId: parentAuthorId,
              replierName: userName,
              listingTitle: listingTitle,
              commentId: created.id,
              listingId: listingId,
            );
          }
        }
      } catch (e) {
        AppLogger.w('addComment notification failed: $e');
      }

      return created;
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
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Notify comment author (not self)
      try {
        final comment = await _supabase
            .from('comments')
            .select('user_id, listing_id')
            .eq('id', commentId)
            .maybeSingle();
        final authorId = comment?['user_id']?.toString();
        final listingId = comment?['listing_id']?.toString();
        if (authorId != null && listingId != null && authorId != user.id) {
          // Fetch liker name and listing title
          Map<String, dynamic>? likerRow;
          try {
            likerRow = await _supabase
                .from('users')
                .select('display_name, full_name, username, email')
                .eq('id', user.id)
                .maybeSingle();
          } catch (e) {
            try {
              likerRow = await _supabase
                  .from('users')
                  .select('display_name, username, email')
                  .eq('id', user.id)
                  .maybeSingle();
            } catch (_) {}
          }
          String likerName = (likerRow?['display_name'] ?? likerRow?['full_name'] ?? likerRow?['username'] ?? '').toString();
          if (likerName.isEmpty) {
            final email = (likerRow?['email'] ?? user.email ?? '').toString();
            if (email.isNotEmpty) likerName = email.split('@').first;
          }
          if (likerName.isEmpty) likerName = 'Someone';

          final listing = await _supabase
              .from('listings')
              .select('title')
              .eq('id', listingId)
              .maybeSingle();
          final listingTitle = (listing?['title'] ?? 'your listing').toString();

          await NotificationService.sendCommentLikeNotification(
            commentAuthorId: authorId,
            likerName: likerName,
            listingTitle: listingTitle,
            commentId: commentId,
            listingId: listingId,
          );
        }
      } catch (e) {
        AppLogger.w('likeComment notification failed: $e');
      }
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
      // Enrich with user profiles and override anonymous names
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
              .select('id, name, display_name, full_name, username, email, photo_url')
              .inFilter('id', userIds);
          for (final u in fetched) {
            userMap[u['id']] = u;
          }
        } catch (_) {
          try {
            final fetched = await _supabase
                .from('users')
                .select('id, name, display_name, full_name, username, photo_url')
                .inFilter('id', userIds);
            for (final u in fetched) {
              userMap[u['id']] = u;
            }
          } catch (_) {}
        }
      }
      return response.map((r) {
        final u = userMap[r['user_id']];
        if (u != null) {
          final copy = Map<String, dynamic>.from(r);
          copy['users'] = u;
          final current = (copy['user_name'] ?? '').toString().trim();
          if (current.isEmpty || current.toLowerCase() == 'anonymous') {
            final best = (u['display_name'] ?? u['name'] ?? u['full_name'] ?? u['username'] ?? '').toString().trim();
            if (best.isNotEmpty) {
              copy['user_name'] = best;
            }
          }
          return Comment.fromJson(copy);
        }
        return Comment.fromJson(r);
      }).toList();
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
              .select('id, name, display_name, full_name, username, email, photo_url')
              .inFilter('id', userIds);
          for (final u in fetched) {
            userMap[u['id']] = u;
          }
        } catch (_) {
          // Fallback if some columns like email don't exist
          try {
            final fetched = await _supabase
                .from('users')
                .select('id, name, display_name, full_name, username, photo_url')
                .inFilter('id', userIds);
            for (final u in fetched) {
              userMap[u['id']] = u;
            }
          } catch (_) {}
        }
      }
      return response.map((r) {
        final u = userMap[r['user_id']];
        if (u != null) {
          final copy = Map<String, dynamic>.from(r);
          copy['users'] = u; // leveraged by model
          // Override placeholder names if needed
          final current = (copy['user_name'] ?? '').toString().trim();
          if (current.isEmpty || current.toLowerCase() == 'anonymous') {
            final best = (u['display_name'] ?? u['name'] ?? u['full_name'] ?? u['username'] ?? '').toString().trim();
            if (best.isNotEmpty) copy['user_name'] = best;
          }
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
          // Identify any user_ids with missing or placeholder user_name to fill
          final missing = rows
              .where((r) {
                final un = (r['user_name'] ?? '').toString().trim();
                return un.isEmpty || un.toLowerCase() == 'anonymous';
              })
              .map((r) => r['user_id'] as String?)
              .whereType<String>()
              .toSet();
          Map<String, Map<String, dynamic>> userMap = {};
          if (missing.isNotEmpty) {
            try {
              final fetched = await _supabase
                  .from('users')
                  .select('id, name, display_name, full_name, username, email, photo_url')
                  .inFilter('id', missing.toList());
              for (final u in fetched) {
                userMap[u['id']] = u;
              }
            } catch (_) {
              try {
                final fetched = await _supabase
                    .from('users')
                    .select('id, name, display_name, full_name, username, photo_url')
                    .inFilter('id', missing.toList());
                for (final u in fetched) {
                  userMap[u['id']] = u;
                }
              } catch (_) {}
            }
          }
          final enriched = rows.map((r) {
            final un = (r['user_name'] ?? '').toString().trim();
            final u = userMap[r['user_id']];
            if (u != null) {
              r = Map<String, dynamic>.from(r);
              r['users'] = u; // so Comment.fromJson can extract/override
              if (un.isEmpty || un.toLowerCase() == 'anonymous') {
                final best = (u['display_name'] ?? u['name'] ?? u['full_name'] ?? u['username'] ?? '').toString().trim();
                if (best.isNotEmpty) {
                  r['user_name'] = best;
                }
              }
            }
            return Comment.fromJson(r);
          }).toList();
          return enriched;
        });
  }
}
