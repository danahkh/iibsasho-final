import 'package:flutter/material.dart';
import '../constant/app_color.dart';
import '../core/services/notification_service.dart';
import '../core/services/chat_service.dart' as Chats;
import '../core/model/chat.dart';
import '../core/utils/supabase_helper.dart';

/// Bottom navigation bar (without a dedicated Search icon). Matches PageSwitcher ordering.
class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Chats (with unread badge)
              StreamBuilder<List<Chat>>(
                stream: () {
                  final u = SupabaseHelper.currentUser;
                  if (u == null) return Stream.value(<Chat>[]);
                  return Chats.ChatService.getUserChats(u.id);
                }(),
                builder: (context, snapshot) {
                  final chats = snapshot.data ?? const <Chat>[];
                  final unread = chats.fold<int>(0, (sum, c) => sum + (c.unreadCount));
                  return _buildNavItem(index: 0, icon: Icons.chat_bubble_outline, label: 'Chats', badgeCount: unread);
                },
              ),
              // Notifications (with unread badge)
              StreamBuilder(
                stream: NotificationService.getUserNotifications(),
                builder: (context, snapshot) {
                  final notifications = snapshot.data as List? ?? const [];
                  final unread = notifications.where((n) => !(n.isRead ?? false)).length;
                  return _buildNavItem(index: 1, icon: Icons.notifications_outlined, label: 'Alerts', badgeCount: unread);
                },
              ),
              _buildCreateButton(),
              _buildNavItem(index: 3, icon: Icons.favorite_outline, label: 'Favorites'),
              _buildNavItem(index: 4, icon: Icons.home_outlined, label: 'Home'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    final bool active = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 24, color: active ? AppColor.primary : AppColor.primary.withOpacity(0.5)),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColor.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: TextStyle(
                          color: AppColor.textLight,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColor.primary : AppColor.primary.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: active ? 1 : 0,
              child: Container(
                height: 3,
                width: 20,
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    // Index 2 in the page list is the create listing page
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColor.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColor.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }
}
