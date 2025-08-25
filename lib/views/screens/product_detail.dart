import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/app_logger.dart';
import 'package:iibsasho/core/model/listing.dart';
import 'package:iibsasho/core/model/user.dart';
import 'package:iibsasho/core/model/comment.dart';
import 'package:iibsasho/core/services/favorite_service.dart';
import 'package:iibsasho/core/services/comment_service.dart';
import 'package:iibsasho/core/services/chat_service.dart' as TupleChat;
import 'package:iibsasho/core/services/listing_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:iibsasho/widgets/standard_scaffold.dart';
import 'package:iibsasho/views/screens/chat_detail_page.dart';
import '../../constant/app_color.dart';
import '../../core/utils/supabase_helper.dart';
import '../../widgets/expandable_description.dart';
import 'login_page.dart';

class ListingDetailPage extends StatefulWidget {
  final Listing listing;
  const ListingDetailPage({super.key, required this.listing});

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  bool isFavorited = false;
  List<Comment> comments = []; // includes both top-level and replies
  Set<String> likedCommentIds = {};
  String? replyingToCommentId; // which comment is being replied to
  final TextEditingController _replyController = TextEditingController();
  bool loadingLikes = false;
  int commentsShown = 20;
  bool loadingMoreComments = false;
  bool allCommentsLoaded = false;
  List<Listing> recommendedListings = [];
  bool loadingRecommendations = false;
  final TextEditingController _commentController = TextEditingController();
  int selectedImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Start with a high initial page to enable infinite scrolling
    _pageController = PageController(initialPage: selectedImageIndex + 10000);
    _loadFavoriteStatus();
    _loadComments();
  _loadRecommendations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
  _replyController.dispose();
    super.dispose();
  }

  void _loadFavoriteStatus() async {
    // Check if listing is favorited by current user from database
    if (SupabaseHelper.currentUser == null) {
      setState(() {
        isFavorited = false;
      });
      return;
    }

    try {
      final isCurrentlyFavorited = await FavoriteService.isFavorite(widget.listing.id);
  if (!mounted) return;
  setState(() { isFavorited = isCurrentlyFavorited; });
    } catch (e) {
  AppLogger.e('Error loading favorite status', e);
  if (mounted) setState(() { isFavorited = false; });
    }
  }

  void _loadComments() async {
    // Load comments for this listing from database
    try {
      final loadedComments = await CommentService.getComments(widget.listing.id);
  if (!mounted) return;
  setState(() { comments = loadedComments; });
      if (comments.length <= commentsShown) {
        allCommentsLoaded = true;
      }
      _loadLikedComments();
    } catch (e) {
      AppLogger.e('Error loading comments', e);
      if (mounted) setState(() { comments = []; });
    }
  }

  Future<void> _loadMoreComments() async {
    if (allCommentsLoaded || loadingMoreComments) return;
    setState(() { loadingMoreComments = true; });
    try {
      final fresh = await CommentService.getComments(widget.listing.id);
      setState(() {
        comments = fresh;
        commentsShown += 20;
        if (commentsShown >= comments.where((c)=>c.parentId==null).length) {
          allCommentsLoaded = true;
        }
      });
    } catch (_) {} finally {
      if (mounted) setState(() { loadingMoreComments = false; });
    }
  }

  Future<void> _loadRecommendations() async {
    if (loadingRecommendations) return;
    setState(() { loadingRecommendations = true; });
    try {
      // 1. Same subcategory
      List<Listing> pool = (await ListingService.fetchListings(
        category: widget.listing.category,
        subcategory: widget.listing.subcategory,
        limit: 60,
      )).where((l)=> l.id != widget.listing.id).toList();
      // 2. Same category fallback
      if (pool.isEmpty) {
        pool = (await ListingService.fetchListings(
          category: widget.listing.category,
          limit: 60,
        )).where((l)=> l.id != widget.listing.id).toList();
      }
      // 3. Global fallback
      if (pool.isEmpty) {
        pool = (await ListingService.fetchListings(limit: 80)).where((l)=> l.id != widget.listing.id).toList();
      }
      // Build favorite counts map in one query (avoid per-listing calls)
      final supabase = Supabase.instance.client;
      final ids = pool.map((e)=> e.id).toSet().toList();
      Map<String,int> favCounts = {};
      if (ids.isNotEmpty) {
        try {
          final favRows = await supabase.from('favorites').select('listing_id').inFilter('listing_id', ids);
          for (final row in favRows) {
            final id = row['listing_id']?.toString();
            if (id==null) continue;
            favCounts[id] = (favCounts[id] ?? 0) + 1;
          }
        } catch (e) {
          AppLogger.e('Favorite aggregation failed', e);
        }
      }
      pool.sort((a,b){
        int promoted = (b.isPromoted?1:0) - (a.isPromoted?1:0); if (promoted!=0) return promoted;
        int featured = (b.isFeatured?1:0) - (a.isFeatured?1:0); if (featured!=0) return featured;
        int liked = (favCounts[b.id]??0) - (favCounts[a.id]??0); if (liked!=0) return liked;
        int views = b.viewCount.compareTo(a.viewCount); if (views!=0) return views;
        return b.createdAt.compareTo(a.createdAt);
      });
      if (mounted) setState(() { recommendedListings = pool.take(40).toList(); });
    } catch (e) {
      AppLogger.e('Error loading recommendations', e);
    } finally {
      if (mounted) setState(() { loadingRecommendations = false; });
    }
  }

  void _loadLikedComments() async {
    if (SupabaseHelper.currentUser == null) return;
    setState(() { loadingLikes = true; });
    try {
      final ids = await CommentService.getUserLikedCommentIds(widget.listing.id);
      setState(() {
        likedCommentIds = ids.toSet();
      });
    } catch (_) {} finally {
      if (mounted) setState(() { loadingLikes = false; });
    }
  }

  void _addComment(String commentText) async {
    if (SupabaseHelper.currentUser == null) {
      _showAuthRequiredDialog('add a comment');
      return;
    }

    if (commentText.trim().isEmpty) return;
    try {
      final newComment = await SupabaseHelper.guardNetwork<Comment?>(
        context,
        () async {
          return await CommentService.addComment(
            listingId: widget.listing.id,
            text: commentText.trim(),
          );
        },
        actionName: 'add a comment',
      );

      if (newComment == null) {
        // Either offline or network error already handled with a SnackBar
        return;
      }

      setState(() {
        comments.insert(0, newComment);
        // ensure counts state
        if (comments.where((c)=>c.parentId==null).length > commentsShown) {
          allCommentsLoaded = false;
        }
      });

      _commentController.clear();

      _showSuccessDialog(
        'Comment Added!',
        'Your comment has been successfully added to this listing.',
      );
    } catch (e) {
      _showErrorDialog(
        'Comment Error',
        'Unable to add comment. Please try again. $e',
      );
    }
  }

  void _showEditCommentDialog(Comment comment) {
    final controller = TextEditingController(text: comment.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Edit Comment'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          minLines: 2,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Update your comment',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              final currentUser = SupabaseHelper.currentUser;
              if (currentUser == null) return;
              final ok = await CommentService.updateComment(
                commentId: comment.id,
                userId: currentUser.id,
                newContent: text,
              );
              if (ok) {
                setState(() {
                  final idx = comments.indexWhere((c) => c.id == comment.id);
                  if (idx != -1) {
                    comments[idx] = Comment(
                      id: comment.id,
                      listingId: comment.listingId,
                      userId: comment.userId,
                      userName: comment.userName,
                      userPhotoUrl: comment.userPhotoUrl,
                      text: text,
                      createdAt: comment.createdAt,
                      parentId: comment.parentId,
                      likeCount: comment.likeCount,
                    );
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Comment updated'), backgroundColor: AppColor.success),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update comment'), backgroundColor: AppColor.error),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addReply(String parentId, String replyText) async {
    if (SupabaseHelper.currentUser == null) {
      _showAuthRequiredDialog('reply to a comment');
      return;
    }
    if (replyText.trim().isEmpty) return;
    try {
      final newReply = await SupabaseHelper.guardNetwork<Comment?>(
        context,
        () async {
          return await CommentService.addComment(
            listingId: widget.listing.id,
            text: replyText.trim(),
            parentId: parentId,
          );
        },
        actionName: 'add a reply',
      );
      if (newReply == null) return;
      setState(() {
        comments.insert(0, newReply);
        replyingToCommentId = null;
        _replyController.clear();
      });
    } catch (e) {
      _showErrorDialog('Reply Error', 'Unable to add reply. Please try again. $e');
    }
  }

  void _toggleLike(Comment comment) async {
    if (SupabaseHelper.currentUser == null) {
      _showAuthRequiredDialog('like a comment');
      return;
    }
    final alreadyLiked = likedCommentIds.contains(comment.id);
    // Optimistic update
    setState(() {
      if (alreadyLiked) {
        likedCommentIds.remove(comment.id);
        comment = Comment(
          id: comment.id,
          listingId: comment.listingId,
          userId: comment.userId,
          userName: comment.userName,
          userPhotoUrl: comment.userPhotoUrl,
          text: comment.text,
          createdAt: comment.createdAt,
          parentId: comment.parentId,
          likeCount: (comment.likeCount - 1).clamp(0, 1 << 31),
        );
      } else {
        likedCommentIds.add(comment.id);
        comment = Comment(
          id: comment.id,
          listingId: comment.listingId,
          userId: comment.userId,
          userName: comment.userName,
          userPhotoUrl: comment.userPhotoUrl,
          text: comment.text,
          createdAt: comment.createdAt,
          parentId: comment.parentId,
          likeCount: comment.likeCount + 1,
        );
      }
      // replace in list
      final idx = comments.indexWhere((c) => c.id == comment.id);
      if (idx != -1) {
        comments[idx] = comment;
      }
    });
    bool success;
    if (alreadyLiked) {
      success = await CommentService.unlikeComment(comment.id);
    } else {
      success = await CommentService.likeComment(comment.id);
    }
    if (!success) {
      // revert
      _loadComments();
    }
  }

  void _deleteComment(Comment comment) async {
    if (SupabaseHelper.currentUser == null) return;
    final userId = SupabaseHelper.currentUser!.id;
    if (comment.userId != userId) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Comment'),
        content: Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await SupabaseHelper.guardNetwork<bool>(
      context,
      () async => await CommentService.deleteComment(comment.id, userId),
      actionName: 'delete a comment',
    );
    if (success == true) {
      setState(() {
        comments.removeWhere((c) => c.id == comment.id || c.parentId == comment.id); // also remove its replies locally
      });
    }
  }

  void _toggleFavorite() async {
    if (SupabaseHelper.currentUser == null) {
      _showAuthRequiredDialog('favorite this item');
      return;
    }
    
    try {
      final result = await FavoriteService.toggleFavorite(widget.listing.id);

      if (result) {
        // Successfully added
        setState(() {
          isFavorited = true;
        });
        _showSuccessDialog(
          'Added to Favorites!',
          'This item has been added to your favorites list.',
        );
      } else {
        // Could be a successful removal or an error; check current state from DB
        final nowFavorite = await FavoriteService.isFavorite(widget.listing.id);
        setState(() {
          isFavorited = nowFavorite;
        });
        if (!nowFavorite) {
          _showSuccessDialog(
            'Removed from Favorites',
            'This item has been removed from your favorites.',
          );
        } else {
          _showErrorDialog(
            'Failed to Update',
            'Unable to update favorites. Please try again.',
          );
        }
      }
    } catch (e) {
      AppLogger.e('Error toggling favorite', e);
      if (!mounted) return;
      _showErrorDialog(
        'Error',
        'Failed to update favorites. Please check your connection and try again.',
      );
    }
  }

  void _contactSeller() {
    if (SupabaseHelper.currentUser == null) {
      _showAuthRequiredDialog('contact the seller');
      return;
    }

    // Navigate to chat or show contact options
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Contact Seller',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.message, color: AppColor.primary),
              ),
              title: Text('Send Message'),
              subtitle: Text('Start a conversation with the seller'),
              onTap: () {
                Navigator.pop(context);
                _openChat();
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.call, color: Colors.green),
              ),
              title: Text('Call Seller'),
              subtitle: Text('Make a phone call'),
              onTap: () {
                Navigator.pop(context);
                _makeCall();
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _openChat() async {
    if (SupabaseHelper.currentUser == null) {
      _showAuthRequiredDialog('start a chat');
      return;
    }

    // Check if user is trying to chat with themselves
    if (SupabaseHelper.currentUser!.id == widget.listing.userId) {
      _showInfoDialog(
        'Cannot Start Chat',
        'You cannot start a chat with yourself on your own listing.',
      );
      return;
    }

    try {
      final me = SupabaseHelper.currentUser!;
      // Primary path: use tuple columns to create or get chat
      final chat = await TupleChat.ChatService.createChat(
        listingId: widget.listing.id,
        sellerId: widget.listing.userId,
        buyerId: me.id,
        listingTitle: widget.listing.title,
      );
      if (chat != null) {
        // Send a first message that includes a listing reference card
        final initial = 'Hi, I’m interested in: ${widget.listing.title}';
        await TupleChat.ChatService.sendMessage(
          chatId: chat.id,
          senderId: me.id,
          message: initial,
          type: 'listing_ref',
          metadata: {
            'listingId': widget.listing.id,
            'title': widget.listing.title,
            if (widget.listing.images.isNotEmpty) 'image': widget.listing.images.first,
          },
        );
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatDetailPage(chat: chat),
          ),
        );
        return;
      }
  // No fallback to composite-id path to avoid UUID errors

      _showErrorDialog('Chat Error', 'Unable to start chat with seller. Please try again.');
    } catch (e) {
      _showErrorDialog('Chat Error', 'Unable to start chat with seller. Please try again. $e');
    }
  }

  void _makeCall() {
    // Initiate phone call
    // TODO: Use url_launcher to make actual phone call
    // Example: launch('tel:${sellerPhoneNumber}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling seller...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAuthRequiredDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Authentication Required'),
        content: Text('You need to be logged in to $action.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ),
              );
            },
            child: Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer() {
    return Container(
      height: 400,
      color: Colors.white,
      child: Column(
        children: [
          // Main image viewer with horizontal scroll
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        selectedImageIndex = index % widget.listing.images.length;
                      });
                    },
                    itemCount: null, // Infinite items
                    itemBuilder: (context, index) {
                      final imageIndex = index % widget.listing.images.length;
                      return GestureDetector(
                        onTap: () {
                          _showFullScreenImage(imageIndex);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            border: Border.all(
                              color: AppColor.primary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              widget.listing.images[imageIndex],
                              fit: BoxFit.contain,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[50],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported, size: 80, color: Colors.grey[400]),
                                      SizedBox(height: 8),
                                      Text('Image not available', style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Left arrow
                  if (widget.listing.images.length > 1)
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back_ios, color: AppColor.primary, size: 20),
                            onPressed: () {
                              _pageController.previousPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  // Right arrow
                  if (widget.listing.images.length > 1)
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_forward_ios, color: AppColor.primary, size: 20),
                            onPressed: () {
                              _pageController.nextPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  // Image counter indicator
                  if (widget.listing.images.length > 1)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${selectedImageIndex + 1}/${widget.listing.images.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          // Thumbnail row
          Container(
            height: 80,
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: AppColor.primary.withValues(alpha: 0.2), width: 1),
                bottom: BorderSide(color: AppColor.primary.withValues(alpha: 0.2), width: 1),
              ),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.listing.images.length,
              itemBuilder: (context, index) {
                bool isSelected = index == selectedImageIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedImageIndex = index;
                    });
                    // Calculate the target page for infinite scroll
                    final currentPage = _pageController.page?.round() ?? 0;
                    final targetPage = (currentPage ~/ widget.listing.images.length) * widget.listing.images.length + index;
                    
                    _pageController.animateToPage(
                      targetPage,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 12),
                    width: isSelected ? 70 : 60,
                    height: isSelected ? 70 : 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColor.primary : AppColor.primary.withValues(alpha: 0.4),
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColor.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ] : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        widget.listing.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image, size: 30, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showFullScreenImage(int initialIndex) {
    // Start with a high initial page for infinite scrolling
    PageController pageController = PageController(initialPage: initialIndex + 10000);
    int currentIndex = initialIndex;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${currentIndex + 1} / ${widget.listing.images.length}',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              centerTitle: true,
            ),
            body: Stack(
              children: [
                PageView.builder(
                  controller: pageController,
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index % widget.listing.images.length;
                    });
                  },
                  itemCount: null, // Infinite items
                  itemBuilder: (context, index) {
                    final imageIndex = index % widget.listing.images.length;
                    return InteractiveViewer(
                      child: Center(
                        child: Image.network(
                          widget.listing.images[imageIndex],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, color: Colors.white, size: 64),
                                  SizedBox(height: 16),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                // Left arrow
                if (widget.listing.images.length > 1)
                  Positioned(
                    left: 20,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () {
                            pageController.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                // Right arrow
                if (widget.listing.images.length > 1)
                  Positioned(
                    right: 20,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
                          onPressed: () {
                            pageController.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StandardScaffold(
      title: widget.listing.title,
      currentIndex: 4,
      actions: [
        IconButton(
          icon: Icon(
            isFavorited ? Icons.favorite : Icons.favorite_border,
            color: isFavorited ? Colors.red : Colors.white,
          ),
          onPressed: _toggleFavorite,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Icon(Icons.store, color: Colors.white, size: 20),
        ),
      ],
      body: ListView(
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        children: [
          // Section 1 - Images
          Container(
            width: MediaQuery.of(context).size.width,
            height: 400,
            color: Colors.white,
            child: widget.listing.images.isNotEmpty
                ? _buildImageViewer()
                : Center(
                    child: Container(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 80, color: AppColor.border),
                          SizedBox(height: 16),
                          Text(
                            'No images available',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          // Section 2 - Listing Info
          Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category tags
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColor.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColor.primary.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  widget.listing.category,
                                  style: TextStyle(
                                    color: AppColor.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (widget.listing.subcategory.isNotEmpty) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Text(
                                    widget.listing.subcategory,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            widget.listing.title,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'poppins', color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '\$${widget.listing.price.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.green),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Listing details row
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.visibility,
                          label: 'Views',
                          value: '${widget.listing.viewCount}',
                          color: Colors.blue,
                        ),
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.schedule,
                          label: 'Posted',
                          value: _formatDate(widget.listing.createdAt),
                          color: Colors.orange,
                        ),
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.check_circle,
                          label: 'Condition',
                          value: widget.listing.condition,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                ExpandableDescription(description: widget.listing.description),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red, size: 20),
                    SizedBox(width: 4),
                    Expanded(child: Text(widget.listing.location, style: TextStyle(color: Colors.black54))),
                    SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _openDirections,
                      icon: Icon(Icons.directions, size: 18, color: AppColor.primary),
                      label: Text('Get directions', style: TextStyle(color: AppColor.primary)),
                      style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _contactSeller,
                        icon: Icon(Icons.message),
                        label: Text('Contact Seller'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    IconButton(
                      onPressed: _toggleFavorite,
                      icon: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isFavorited ? Colors.red : AppColor.primary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.all(12),
                        shape: CircleBorder(
                          side: BorderSide(color: AppColor.border),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                // Seller Info
                FutureBuilder<AppUser?>(
                  future: AppUser.fetchById(widget.listing.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Loading seller info...'),
                        ],
                      );
                    }
                    if (!snapshot.hasData || snapshot.data == null) {
                      return Text('Seller info not available', style: TextStyle(color: Colors.black54));
                    }
                    final user = snapshot.data!;
                    return Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColor.border),
                      ),
                      child: Row(
                        children: [
                          if (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                            CircleAvatar(backgroundImage: NetworkImage(user.photoUrl!), radius: 20)
                          else
                            CircleAvatar(radius: 20, child: Icon(Icons.person)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                Text(user.email, style: TextStyle(color: Colors.black54, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),
                // Comments Section
                Column(
                  children: [
                    SizedBox(height: 16),
                    Text(
                      'Comments (${comments.length})',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColor.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColor.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColor.primary),
                              ),
                            ),
                            maxLines: 3,
                          ),
                          SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                _addComment(_commentController.text);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Post Comment'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    comments.isEmpty
                        ? Container(
                            padding: EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                                SizedBox(height: 16),
                                Text('No comments yet', style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500)),
                                SizedBox(height: 8),
                                Text('Be the first to comment on this listing', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              ListView.separated(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: (() {
                                  final topLevel = comments.where((c) => c.parentId == null).toList();
                                  final count = topLevel.length;
                                  return count < commentsShown ? count : commentsShown;
                                })(),
                                separatorBuilder: (_, __) => SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final topLevel = comments.where((c) => c.parentId == null).toList()
                                    ..sort((a,b)=> b.createdAt.compareTo(a.createdAt));
                                  final subset = topLevel.take(commentsShown).toList();
                                  final comment = subset[index];
                                  final replies = comments.where((c) => c.parentId == comment.id).toList()
                                    ..sort((a,b)=> a.createdAt.compareTo(b.createdAt));
                                  final isLiked = likedCommentIds.contains(comment.id);
                                  final displayName = (comment.userName.isNotEmpty) ? comment.userName : 'Anonymous';
                                  return Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColor.border),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: AppColor.primary.withOpacity(0.1),
                                              child: Text(displayName[0].toUpperCase(), style: TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(displayName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                                      ),
                                                      if (SupabaseHelper.currentUser?.id == comment.userId)
                                                        PopupMenuButton<String>(
                                                          onSelected: (val) {
                                                            if (val == 'delete') {
                                                              _deleteComment(comment);
                                                            } else if (val == 'edit') {
                                                              _showEditCommentDialog(comment);
                                                            }
                                                          },
                                                          itemBuilder: (_) => [
                                                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                                                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                                                          ],
                                                          icon: Icon(Icons.more_vert, size: 18),
                                                        ),
                                                    ],
                                                  ),
                                                  Text(_formatTimestamp(comment.createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Text(comment.text, style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: () => _toggleLike(comment),
                                              child: Row(
                                                children: [
                                                  Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 18, color: isLiked ? Colors.red : Colors.grey[600]),
                                                  SizedBox(width: 4),
                                                  Text(comment.likeCount > 0 ? '${comment.likeCount}' : '', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            TextButton(
                                              onPressed: () { setState(() { replyingToCommentId = (replyingToCommentId == comment.id) ? null : comment.id; }); },
                                              child: Text('Reply'),
                                            ),
                                            if (replies.isNotEmpty)
                                              Text('${replies.length} repl${replies.length == 1 ? 'y' : 'ies'}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                          ],
                                        ),
                                        if (replyingToCommentId == comment.id)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Column(
                                              children: [
                                                TextField(
                                                  controller: _replyController,
                                                  decoration: InputDecoration(hintText: 'Write a reply...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                                  minLines: 1,
                                                  maxLines: 3,
                                                ),
                                                SizedBox(height: 6),
                                                Align(
                                                  alignment: Alignment.centerRight,
                                                  child: ElevatedButton(
                                                    onPressed: () => _addReply(comment.id, _replyController.text),
                                                    style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, foregroundColor: Colors.white),
                                                    child: Text('Post Reply'),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        if (replies.isNotEmpty) ...[
                                          SizedBox(height: 8),
                                          Column(
                                            children: replies.map((r) {
                                              final isReplyLiked = likedCommentIds.contains(r.id);
                                              final replyName = r.userName.isNotEmpty ? r.userName : 'Anonymous';
                                              return Container(
                                                margin: EdgeInsets.only(top: 6, left: 32),
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: AppColor.border.withOpacity(0.6)),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(child: Text(replyName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                                                        Text(_formatTimestamp(r.createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                                        if (SupabaseHelper.currentUser?.id == r.userId) ...[
                                                          SizedBox(width: 4),
                                                          GestureDetector(onTap: () => _deleteComment(r), child: Icon(Icons.delete_outline, size: 16, color: Colors.redAccent))
                                                        ]
                                                      ],
                                                    ),
                                                    SizedBox(height: 6),
                                                    Text(r.text, style: TextStyle(fontSize: 13, color: Colors.black87)),
                                                    SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        GestureDetector(
                                                          onTap: () => _toggleLike(r),
                                                          child: Row(
                                                            children: [
                                                              Icon(isReplyLiked ? Icons.favorite : Icons.favorite_border, size: 16, color: isReplyLiked ? Colors.red : Colors.grey[600]),
                                                              SizedBox(width: 3),
                                                              Text(r.likeCount.toString(), style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          )
                                        ]
                                      ],
                                    ),
                                  );
                                },
                              ),
                              if (!allCommentsLoaded) ...[
                                SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadMoreComments,
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, foregroundColor: Colors.white),
                                  child: loadingMoreComments ? SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : Text('Show more comments'),
                                ),
                              ]
                            ],
                          ),
                    SizedBox(height: 24),
                    Align(alignment: Alignment.centerLeft, child: Text('Recommended', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                    SizedBox(height: 12),
                    if (loadingRecommendations)
                      SizedBox(height:140, child: Center(child: CircularProgressIndicator()))
                    else if (recommendedListings.isEmpty)
                      Text('No recommendations available', style: TextStyle(color: Colors.black54))
                    else
                      _buildRecommendationCarousel(),
                    SizedBox(height: 24),
                  ],
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections() async {
    final lat = widget.listing.latitude;
    final lng = widget.listing.longitude;
    // Fallback to search by location name if coordinates missing
    final hasCoords = lat != 0 && lng != 0;
    final encodedName = Uri.encodeComponent(widget.listing.location.isNotEmpty ? widget.listing.location : widget.listing.title);

    // Prefer Google Maps on all platforms; fall back to geo: deep link then Apple Maps as last resort
    final googleUri = hasCoords
        ? Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedName');

    final candidates = <Uri>[
      googleUri,
      if (hasCoords) Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(widget.listing.title)})'),
      if (hasCoords) Uri.parse('https://maps.apple.com/?daddr=$lat,$lng'),
    ];

    for (final uri in candidates) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        return;
      }
    }

    // As a last resort, show an error
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open maps on this device.')),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecommendationCarousel() {
    final chunks = <List<Listing>>[];
    for (var i = 0; i < recommendedListings.length; i += 5) {
      chunks.add(recommendedListings.sublist(i, i + 5 > recommendedListings.length ? recommendedListings.length : i + 5));
    }
    return SizedBox(
      height: 260,
      child: PageView.builder(
        itemCount: chunks.length,
        controller: PageController(viewportFraction: 0.95),
        itemBuilder: (context, pageIndex) {
          final slice = chunks[pageIndex];
          return Row(
            children: slice.asMap().entries.map((entry) {
              final listing = entry.value;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ListingDetailPage(listing: listing)),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(left: entry.key == 0 ? 0 : 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColor.border.withOpacity(0.6)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            child: listing.images.isNotEmpty
                                ? Image.network(
                                    listing.images.first,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: Icon(Icons.image)),
                                  )
                                : Container(color: Colors.grey[200], child: Icon(Icons.image)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              SizedBox(height: 4),
                              Text(listing.formattedPrice, style: TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // Dialog helper methods for better user feedback
  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppColor.success, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: AppColor.textSecondary,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.error, color: AppColor.error, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: AppColor.textSecondary,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.info, color: AppColor.primary, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: AppColor.textSecondary,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}