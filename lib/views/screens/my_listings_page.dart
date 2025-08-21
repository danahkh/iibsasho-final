import 'package:flutter/material.dart';
import '../../core/model/listing.dart';
import '../../core/services/listing_service.dart';
import '../../constant/app_color.dart';
import '../../core/utils/supabase_helper.dart';
import 'product_detail.dart';
import 'create_listing_page.dart';
import '../../widgets/standard_scaffold.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  @override
  Widget build(BuildContext context) {
    final currentUser = SupabaseHelper.currentUser;
    return StandardScaffold(
      title: 'My Listings',
      currentIndex: 4,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            if (!SupabaseHelper.requireAuth(context, feature: 'add listing')) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateListingPage(listing: null)),
            ).then((_) => setState(() {}));
          },
        ),
      ],
      body: currentUser == null
          ? _buildNotLoggedInView()
      : StreamBuilder<List<Listing>>(
        stream: ListingService.getMyListingsIncludingDrafts(currentUser.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingView();
                }
                if (snapshot.hasError) {
                  return _buildErrorView(snapshot.error.toString());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyView('No listings available');
                }
                
                final myListings = snapshot.data!..sort((a,b)=>b.updatedAt.compareTo(a.updatedAt));
                    
                if (myListings.isEmpty) {
                  return _buildEmptyView('You have no listings yet.\nTap + to create your first listing!');
                }
                
                return _buildListingsView(myListings);
              },
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle, size: 80, color: AppColor.disabled),
          SizedBox(height: 16),
          Text(
            'Please log in to view your listings',
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

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColor.primary),
          SizedBox(height: 16),
          Text(
            'Loading your listings...',
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
            'Error loading listings',
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

  Widget _buildEmptyView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: AppColor.disabled),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: AppColor.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (!SupabaseHelper.requireAuth(context, feature: 'add listing')) {
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateListingPage(listing: null)),
              ).then((_) => setState(() {}));
            },
            icon: Icon(Icons.add),
            label: Text('Create Listing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.textLight,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsView(List<Listing> listings) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      color: AppColor.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final listing = listings[index];
          return _buildListingCard(listing);
        },
      ),
    );
  }

  Widget _buildListingCard(Listing listing) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: AppColor.shadowColor,
      color: AppColor.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColor.border, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListingDetailPage(listing: listing),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColor.disabled.withOpacity(0.1),
                  border: Border.all(color: AppColor.border),
                ),
                child: listing.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          listing.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image, color: AppColor.disabled);
                          },
                        ),
                      )
                    : Icon(Icons.image, color: AppColor.disabled),
              ),
              SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      listing.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColor.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '\$${listing.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                        Spacer(),
                        _buildStatusChip(listing),
                      ],
                    ),
                  ],
                ),
              ),
              // Action menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColor.iconSecondary),
                onSelected: (value) => _handleMenuAction(value, listing),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: AppColor.iconPrimary),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (listing.isDraft)
                    PopupMenuItem(
                      value: 'publish',
                      child: Row(
                        children: [
                          Icon(Icons.publish, size: 20, color: AppColor.success),
                          SizedBox(width: 8),
                          Text('Publish', style: TextStyle(color: AppColor.success)),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: AppColor.error),
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
      ),
    );
  }

  Widget _buildStatusChip(Listing l) {
    String label;
    Color color;
    if (l.isDraft) {
      label = 'DRAFT';
      color = Colors.orange;
    } else if (l.isActive) {
      label = 'ACTIVE';
      color = AppColor.success;
    } else {
      label = 'INACTIVE';
      color = AppColor.disabled;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Listing listing) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateListingPage(listing: listing),
          ),
        ).then((_) => setState(() {}));
        break;
      case 'publish':
        _publishDraft(listing);
        break;
      case 'delete':
        _showDeleteConfirmation(listing);
        break;
    }
  }

  Future<void> _publishDraft(Listing l) async {
    try {
      final updated = Listing(
        id: l.id,
        title: l.title,
        description: l.description,
        images: l.images,
        videos: l.videos,
        price: l.price,
        category: l.category,
        subcategory: l.subcategory,
        location: l.location,
        latitude: l.latitude,
        longitude: l.longitude,
        condition: l.condition,
        userId: l.userId,
        userName: l.userName,
        userEmail: l.userEmail,
        userPhotoUrl: l.userPhotoUrl,
        createdAt: l.createdAt,
        updatedAt: DateTime.now(),
        isActive: true,
        viewCount: l.viewCount,
        isFeatured: l.isFeatured,
        isPromoted: l.isPromoted,
        isDraft: false,
      );
      await ListingService.updateListing(l.id, updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Draft published'), backgroundColor: AppColor.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Publish failed: $e'), backgroundColor: AppColor.error),
      );
    }
  }

  void _showDeleteConfirmation(Listing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.cardBackground,
        title: Text('Delete Listing', style: TextStyle(color: AppColor.textPrimary)),
        content: Text(
          'Are you sure you want to delete "${listing.title}"? This action cannot be undone.',
          style: TextStyle(color: AppColor.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColor.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ListingService.deleteListing(listing.id);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Listing deleted successfully'),
                    backgroundColor: AppColor.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting listing: $e'),
                    backgroundColor: AppColor.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              foregroundColor: AppColor.textLight,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
