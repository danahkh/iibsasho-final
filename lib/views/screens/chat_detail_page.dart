import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../core/model/chat.dart';
import '../../core/services/chat_service.dart';
import '../../core/utils/supabase_helper.dart';

class ChatDetailPage extends StatefulWidget {
  final Chat chat;

  const ChatDetailPage({
    super.key,
    required this.chat,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening chat
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    final currentUser = SupabaseHelper.currentUser;
    if (currentUser != null) {
      await ChatService.markMessagesAsRead(widget.chat.id, currentUser.id);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final currentUser = SupabaseHelper.currentUser;
    if (currentUser == null || _messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    final success = await SupabaseHelper.guardNetwork<bool>(
      context,
      () => ChatService.sendMessage(
        chatId: widget.chat.id,
        senderId: currentUser.id,
        message: messageText,
      ),
      actionName: 'send message',
    ) ?? false;

    setState(() {
      _isSending = false;
    });

    if (success) {
      _scrollToBottom();
    } else {
      // Show error and restore message
      _messageController.text = messageText;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: AppColor.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = SupabaseHelper.currentUser;
    
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        elevation: 2,
        shadowColor: AppColor.shadowColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColor.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColor.textLight.withOpacity(0.1),
              backgroundImage: widget.chat.otherUserAvatar != null
                  ? NetworkImage(widget.chat.otherUserAvatar!)
                  : null,
              child: widget.chat.otherUserAvatar == null
                  ? Text(
                      (() {
                        final name = widget.chat.otherUserName;
                        final seed = (name.isNotEmpty
                                ? name
                                : (widget.chat.listingTitle.isNotEmpty
                                    ? widget.chat.listingTitle
                                    : 'C'))
                            .trim();
                        if (seed.isEmpty) return 'C';
                        return seed.substring(0, 1).toUpperCase();
                      })(),
                      style: TextStyle(
                        color: AppColor.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.otherUserName.isNotEmpty
                        ? widget.chat.otherUserName
                        : 'Chat',
                    style: TextStyle(
                      color: AppColor.textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.chat.listingTitle,
                    style: TextStyle(
                      color: AppColor.textLight.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColor.textLight),
            onPressed: () => _showChatOptions(),
          ),
        ],
      ),
      body: currentUser == null
          ? _buildNotLoggedInView()
          : Column(
              children: [
                // Listing info banner
                _buildListingBanner(),
                // Messages
                Expanded(
                  child: StreamBuilder<List<Message>>(
                    stream: ChatService.getChatMessages(widget.chat.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingView();
                      }

                      if (snapshot.hasError) {
                        return _buildErrorView(snapshot.error.toString());
                      }

                      final messages = snapshot.data ?? [];
                      
                      if (messages.isEmpty) {
                        return _buildEmptyView();
                      }

                      // Scroll to bottom when messages update
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isCurrentUser = message.senderId == currentUser.id;
                          final showTimestamp = index == 0 || 
                              _shouldShowTimestamp(messages[index - 1], message);
                          
                          final isFirst = index == 0;
                          final isListingRef = (message.type == 'listing_ref') && (message.metadata != null);
                          return Column(
                            children: [
                              if (showTimestamp) _buildTimestamp(message.timestamp),
                              if (isFirst && isListingRef)
                                _buildListingReferenceCard(message.metadata!),
                              _buildMessageBubble(message, isCurrentUser),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                // Message input
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 80, color: AppColor.disabled),
          SizedBox(height: 16),
          Text(
            'Please log in to access chat',
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

  Widget _buildListingBanner() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColor.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_bag, color: AppColor.primary, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'About: ${widget.chat.listingTitle}',
              style: TextStyle(
                color: AppColor.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate to listing detail
              Navigator.pushNamed(
                context,
                '/listing/${widget.chat.listingId}',
              );
            },
            child: Text(
              'View',
              style: TextStyle(color: AppColor.primary, fontSize: 12),
            ),
          ),
        ],
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
            'Loading messages...',
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
            'Error loading messages',
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

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: AppColor.disabled),
          SizedBox(height: 16),
          Text(
            'Start your conversation!',
            style: TextStyle(
              fontSize: 18,
              color: AppColor.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Send your first message below',
            style: TextStyle(
              fontSize: 14,
              color: AppColor.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowTimestamp(Message previousMessage, Message currentMessage) {
    final timeDiff = currentMessage.timestamp.difference(previousMessage.timestamp);
    return timeDiff.inMinutes > 15;
  }

  Widget _buildTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    String timeText;
    if (messageDate == today) {
      timeText = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      timeText = '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        timeText,
        style: TextStyle(
          color: AppColor.textSecondary,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
    return Container(
      margin: EdgeInsets.only(
        bottom: 4,
        left: isCurrentUser ? 48 : 0,
        right: isCurrentUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: 
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? AppColor.primary 
                  : AppColor.cardBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Text(
              message.message,
              style: TextStyle(
                color: isCurrentUser 
                    ? AppColor.textLight 
                    : AppColor.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingReferenceCard(Map<String, dynamic> meta) {
    final listingId = meta['listingId']?.toString() ?? '';
    final title = meta['title']?.toString() ?? 'Listing';
    final imageUrl = meta['image']?.toString();
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.divider),
      ),
      child: Row(
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(imageUrl, width: 56, height: 56, fit: BoxFit.cover),
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColor.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.shopping_bag, color: AppColor.primary),
            ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Listing reference', style: TextStyle(color: AppColor.textSecondary, fontSize: 12)),
                SizedBox(height: 4),
                Text(title, style: TextStyle(color: AppColor.textPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              if (listingId.isNotEmpty) {
                Navigator.pushNamed(context, '/listing/$listingId');
              }
            },
            child: Text('View', style: TextStyle(color: AppColor.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColor.cardBackground,
        border: Border(
          top: BorderSide(color: AppColor.divider, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColor.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColor.border),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: AppColor.placeholder),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(color: AppColor.textPrimary),
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColor.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColor.textLight,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.send, color: AppColor.textLight, size: 20),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColor.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag, color: AppColor.primary),
              title: Text('View Listing', style: TextStyle(color: AppColor.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/listing/${widget.chat.listingId}');
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColor.error),
              title: Text('Delete Chat', style: TextStyle(color: AppColor.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteChat();
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.cardBackground,
        title: Text('Delete Chat', style: TextStyle(color: AppColor.textPrimary)),
        content: Text(
          'Are you sure you want to delete this chat? This action cannot be undone.',
          style: TextStyle(color: AppColor.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColor.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ChatService.deleteChat(widget.chat.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Chat deleted successfully'),
                    backgroundColor: AppColor.success,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: AppColor.error)),
          ),
        ],
      ),
    );
  }
}
