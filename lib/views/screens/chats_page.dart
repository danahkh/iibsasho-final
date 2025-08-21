import 'package:flutter/material.dart';
import 'dart:convert';
import '../../constant/app_color.dart';
import '../../core/utils/supabase_helper.dart';
import '../../core/services/enhanced_chat_service.dart';
import '../../core/utils/app_logger.dart';
import '../../widgets/standard_scaffold.dart';
import 'enhanced_chat_detail_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  @override
  Widget build(BuildContext context) {
    final currentUser = SupabaseHelper.currentUser;
    
    return StandardScaffold(
      title: 'Chats',
      currentIndex: 0,
      actions: [
        if (currentUser != null)
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
      ],
      body: currentUser == null
          ? _buildNotLoggedInView()
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: ChatService.getUserChats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingView();
                }
                
                if (snapshot.hasError) {
                  AppLogger.e('Chat stream error', snapshot.error);
                  return _buildErrorView(snapshot.error.toString());
                }
                
                final chats = snapshot.data ?? [];
                
                if (chats.isEmpty) {
                  return _buildEmptyView();
                }
                
                return _buildChatsView(chats);
              },
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColor.primary),
          SizedBox(height: 16),
          Text(
            'Loading chats...',
            style: TextStyle(color: AppColor.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: AppColor.error),
          SizedBox(height: 16),
          Text(
            'Error loading chats',
            style: TextStyle(
              fontSize: 18,
              color: AppColor.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: AppColor.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: AppColor.disabled),
          SizedBox(height: 16),
          Text(
            'Please log in to view your chats',
            style: TextStyle(
              fontSize: 18,
              color: AppColor.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.textLight,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: AppColor.disabled),
          SizedBox(height: 16),
          Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColor.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Start conversations by messaging sellers on listings you\'re interested in',
              style: TextStyle(
                fontSize: 14,
                color: AppColor.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.textLight,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Browse Listings'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsView(List<Map<String, dynamic>> chats) {
    return RefreshIndicator(
      onRefresh: () async {
        // Implement refresh functionality
        setState(() {});
      },
      color: AppColor.primary,
      child: Column(
        children: [
          // Active chats header
          Container(
            padding: EdgeInsets.all(16),
            color: AppColor.cardBackground,
            child: Row(
              children: [
                Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${chats.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColor.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chat list
          Expanded(
            child: ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppColor.divider,
                indent: 72,
              ),
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _buildChatItem(chat);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final currentUserId = SupabaseHelper.currentUser?.id ?? '';
    
    // Get unread count for current user
    Map<String, dynamic> unreadCount = {};
    final rawUnread = chat['unread_count'];
    if (rawUnread is Map) {
      unreadCount = Map<String, dynamic>.from(rawUnread);
    } else if (rawUnread is String) {
      // In case it's stored as JSON text
      try {
        unreadCount = Map<String, dynamic>.from(
          (rawUnread.isNotEmpty) ? (jsonDecode(rawUnread) as Map) : {},
        );
      } catch (_) {}
    }
    final myUnreadCount = (unreadCount[currentUserId] ?? 0) is int
        ? unreadCount[currentUserId]
        : int.tryParse('${unreadCount[currentUserId] ?? 0}') ?? 0;
    
    return InkWell(
      onTap: () {
        // Navigate to individual chat
        _openChat(chat);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColor.background,
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColor.primary.withOpacity(0.1),
                  child: Text(
                    (chat['listing_title'] ?? 'C').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppColor.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (myUnreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColor.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text(
                        myUnreadCount > 9 ? '9+' : myUnreadCount.toString(),
                        style: TextStyle(
                          color: AppColor.textLight,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat['listing_title'] ?? 'Chat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: myUnreadCount > 0 
                                ? FontWeight.w600 
                                : FontWeight.w500,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _formatTimestamp(_safeParseTime(chat)),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    chat['last_message'] ?? 'No messages yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: myUnreadCount > 0 
                          ? AppColor.textPrimary 
                          : AppColor.textSecondary,
                      fontWeight: myUnreadCount > 0 
                          ? FontWeight.w500 
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right,
              color: AppColor.iconSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  DateTime _safeParseTime(Map<String, dynamic> chat) {
    final candidates = [
      chat['last_message_time'],
      chat['updated_at'],
      chat['created_at'],
    ];
    for (final c in candidates) {
      if (c is String && c.isNotEmpty) {
        try {
          return DateTime.parse(c);
        } catch (_) {}
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _openChat(Map<String, dynamic> chat) {
    final chatId = (chat['id'] ?? '').toString();
    final listingTitle = (chat['listing_title'] ?? 'Chat').toString();
    final listingId = (chat['listing_id'] ?? '').toString();

    if (chatId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnhancedChatDetailPage(
          chatId: chatId,
          listingTitle: listingTitle,
          listingId: listingId,
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.cardBackground,
        title: Text('Search Chats', style: TextStyle(color: AppColor.textPrimary)),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Search messages...',
            hintStyle: TextStyle(color: AppColor.placeholder),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColor.border),
            ),
          ),
          style: TextStyle(color: AppColor.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColor.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Search', style: TextStyle(color: AppColor.primary)),
          ),
        ],
      ),
    );
  }
}
