import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../core/utils/supabase_helper.dart';
import '../../core/services/notification_service.dart';
import '../../core/model/notification_item.dart';
import '../../widgets/standard_scaffold.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});
  
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    final currentUser = SupabaseHelper.currentUser;

    return StandardScaffold(
      title: 'Notifications',
      currentIndex: 1,
      showBottomNav: false,
      actions: [
        if (currentUser != null)
          StreamBuilder<List<NotificationItem>>(
            stream: NotificationService.getUserNotifications(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.where((n) => !n.isRead).length ?? 0;
              if (unreadCount > 0) {
                return TextButton(
                  onPressed: _markAllAsRead,
                  child: const Text('Mark all read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        if (currentUser != null)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showNotificationSettings,
          ),
      ],
      body: currentUser == null
          ? _buildNotLoggedInView()
          : StreamBuilder<List<NotificationItem>>(
              stream: NotificationService.getUserNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingView();
                }
                
                if (snapshot.hasError) {
                  return _buildErrorView(snapshot.error.toString());
                }
                
                final notifications = snapshot.data ?? [];
                
                if (notifications.isEmpty) {
                  return _buildEmptyView();
                }
                
                return _buildNotificationsView(notifications);
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
            'Loading notifications...',
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
            'Error loading notifications',
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
          Icon(Icons.notifications_off, size: 80, color: AppColor.disabled),
          SizedBox(height: 16),
          Text(
            'Please log in to view notifications',
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

  Widget _buildNotificationsView(List<NotificationItem> notifications) {
    return RefreshIndicator(
      onRefresh: () async {
        // Implement refresh functionality
        setState(() {});
      },
      color: AppColor.primary,
      child: Column(
        children: [
          // Notifications header
          Container(
            padding: EdgeInsets.all(16),
            color: AppColor.cardBackground,
            child: Row(
              children: [
                Text(
                  'Recent',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
                ),
                Spacer(),
                if (notifications.where((n) => !n.isRead).isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColor.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${notifications.where((n) => !n.isRead).length} new',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColor.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Notifications list
          Expanded(
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppColor.divider,
                indent: 72,
              ),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(notification);
              },
            ),
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
          Icon(Icons.notifications_none, size: 80, color: AppColor.disabled),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
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
              'You\'ll receive notifications here when:\n• Someone messages you about your listings\n• Your listings get new activity\n• Important account updates occur',
              style: TextStyle(
                fontSize: 14,
                color: AppColor.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return InkWell(
      onTap: () {
        _handleNotificationTap(notification);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: notification.isRead 
            ? AppColor.background 
            : AppColor.primary.withOpacity(0.05),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTypeColor(notification.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTypeIcon(notification.type),
                color: _getTypeColor(notification.type),
                size: 20,
              ),
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
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification.isRead 
                                ? FontWeight.w500 
                                : FontWeight.w600,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: notification.isRead 
                          ? AppColor.textSecondary 
                          : AppColor.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColor.error,
                  shape: BoxShape.circle,
                ),
              ),
            SizedBox(width: 8),
            // Menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppColor.iconSecondary, size: 20),
              onSelected: (value) => _handleMenuAction(value, notification),
              itemBuilder: (context) => [
                if (!notification.isRead)
                  PopupMenuItem(
                    value: 'mark_read',
                    child: Row(
                      children: [
                        Icon(Icons.mark_email_read, size: 16, color: AppColor.iconPrimary),
                        SizedBox(width: 8),
                        Text('Mark as read'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: AppColor.error),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppColor.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'message':
        return AppColor.primary;
      case 'comment':
        return AppColor.success;
      case 'favorite':
        return AppColor.warning;
      case 'alert':
        return AppColor.accent;
      default:
        return AppColor.disabled;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'comment':
        return Icons.comment;
      case 'favorite':
        return Icons.favorite;
      case 'alert':
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  void _handleNotificationTap(NotificationItem notification) async {
    if (!notification.isRead) {
      await NotificationService.markAsRead(notification.id);
    }
    
    // Handle navigation based on notification type
    switch (notification.type) {
      case 'message':
        // Navigate to chats
        Navigator.pushNamed(context, '/chats');
        break;
      case 'comment':
        // Navigate to the specific listing
        if (notification.relatedId != null) {
          _navigateToListing(notification.relatedId!);
        }
        break;
      case 'favorite':
        // Navigate to the specific listing
        if (notification.relatedId != null) {
          _navigateToListing(notification.relatedId!);
        }
        break;
      default:
        break;
    }
  }

  void _handleMenuAction(String action, NotificationItem notification) async {
    final currentUser = SupabaseHelper.currentUser;
    if (currentUser == null) return;

    switch (action) {
      case 'mark_read':
        await NotificationService.markAsRead(notification.id);
        break;
      case 'delete':
        await NotificationService.deleteNotification(notification.id);
        break;
    }
  }

  void _markAllAsRead() async {
    final currentUser = SupabaseHelper.currentUser;
    if (currentUser == null) return;
    
    await NotificationService.markAllAsRead(currentUser.id);
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.cardBackground,
        title: Text('Notification Settings', style: TextStyle(color: AppColor.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Push notifications', style: TextStyle(color: AppColor.textPrimary)),
              subtitle: Text('Receive notifications on your device', style: TextStyle(color: AppColor.textSecondary)),
              value: true,
              onChanged: (value) {},
              activeColor: AppColor.primary,
            ),
            SwitchListTile(
              title: Text('Email notifications', style: TextStyle(color: AppColor.textPrimary)),
              subtitle: Text('Receive notifications via email', style: TextStyle(color: AppColor.textSecondary)),
              value: false,
              onChanged: (value) {},
              activeColor: AppColor.primary,
            ),
            SwitchListTile(
              title: Text('Marketing updates', style: TextStyle(color: AppColor.textPrimary)),
              subtitle: Text('Receive promotional offers', style: TextStyle(color: AppColor.textSecondary)),
              value: false,
              onChanged: (value) {},
              activeColor: AppColor.primary,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColor.primary)),
          ),
        ],
      ),
    );
  }

  void _navigateToListing(String listingId) {
    // TODO: Navigate to listing detail page with the given listingId
    // This would need to be implemented based on your app's routing structure
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to listing: $listingId')),
    );
  }

  // Removed unused _navigateToChat helper to satisfy analyzer
}
