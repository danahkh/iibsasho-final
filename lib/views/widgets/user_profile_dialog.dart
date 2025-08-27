import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/supabase_helper.dart';
import '../../core/services/listing_service.dart';
import '../../core/model/listing.dart';
import '../../constant/app_color.dart';

class UserProfileDialog extends StatefulWidget {
  final String userId;
  // Optional: handle listing taps (navigate to detail, etc.)
  final void Function(Listing listing)? onListingTap;

  const UserProfileDialog({super.key, required this.userId, this.onListingTap});

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  late Future<_UserData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_UserData> _load() async {
    final client = Supabase.instance.client;
    Map<String, dynamic>? profile;
    try {
      profile = await client
          .from('users')
          .select('id, name, display_name, full_name, username, email, photo_url, bio, created_at')
          .eq('id', widget.userId)
          .maybeSingle();
    } catch (_) {
      profile = null;
    }

    // Get listings (used for grid + counts + fallback name)
    final listings = await ListingService.getUserListings(widget.userId);

    // Derive name
    String name = _displayName(profile);
    if (name == 'User' || name.trim().isEmpty) {
      // Try from listings join
      final fromListing = listings.firstWhere(
        (l) => (l.userName).trim().isNotEmpty,
        orElse: () => listings.isNotEmpty ? listings.first : Listing(
          id: '', title: '', description: '', images: const [], videos: const [], price: 0, category: '', subcategory: '',
          location: '', latitude: 0, longitude: 0, condition: 'used', userId: widget.userId, userName: '', userEmail: '', userPhotoUrl: '',
          createdAt: DateTime.now(), updatedAt: DateTime.now(), isActive: true, viewCount: 0, isFeatured: false, isPromoted: false, isDraft: false,
        ),
      );
      if (fromListing.userName.trim().isNotEmpty) {
        name = fromListing.userName.trim();
      } else {
        // Try latest comment's stored user_name (works thanks to trigger/backfill)
        try {
          final commentRow = await client
              .from('comments')
              .select('user_name')
              .eq('user_id', widget.userId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          final cn = (commentRow?['user_name'] ?? '').toString().trim();
          if (cn.isNotEmpty && cn.toLowerCase() != 'anonymous') name = cn;
        } catch (_) {}
      }
    }

    // Compute metadata
    final totalListings = listings.length;
    final totalViews = listings.fold<int>(0, (sum, l) => sum + (l.viewCount));
    int totalLikes = 0;
    if (listings.isNotEmpty) {
      final ids = listings.map((l) => l.id).toList();
      try {
        final rows = await client
            .from('favorites')
            .select('id')
            .inFilter('listing_id', ids);
        totalLikes = (rows as List).length;
      } catch (_) {}
    }

    return _UserData(
      profile: profile,
      listings: listings,
      displayName: name,
      totalListings: totalListings,
      totalViews: totalViews,
      totalLikes: totalLikes,
    );
  }

  String _firstLetter(String name) {
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _displayName(Map<String, dynamic>? p) {
    if (p == null) return 'User';
    final dn = (p['display_name'] ?? '').toString().trim();
    final n = (p['name'] ?? '').toString().trim();
  if (dn.isNotEmpty) return dn;
  if (n.isNotEmpty) return n;
  final full = (p['full_name'] ?? '').toString().trim();
  if (full.isNotEmpty) return full;
  final uname = (p['username'] ?? '').toString().trim();
  if (uname.isNotEmpty) return uname;
  final email = (p['email'] ?? '').toString();
  if (email.isNotEmpty && email.contains('@')) return email.split('@').first;
  return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            child: FutureBuilder<_UserData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                }
                final data = snapshot.data ?? _UserData.empty();
                final profile = data.profile;
                final listings = data.listings;
                final name = data.displayName.isNotEmpty ? data.displayName : _displayName(profile);
                final photoUrl = (profile?['photo_url'] ?? '').toString();
                return Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        border: Border(bottom: BorderSide(color: AppColor.border)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColor.primary.withOpacity(0.1),
                            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                            child: photoUrl.isEmpty
                                ? Text(_firstLetter(name), style: TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 4,
                                  children: [
                                    _MetaChip(icon: Icons.list_alt, label: '${data.totalListings} listings'),
                                    _MetaChip(icon: Icons.visibility, label: '${data.totalViews} views'),
                                    _MetaChip(icon: Icons.favorite_border, label: '${data.totalLikes} likes'),
                                  ],
                                ),
                                if ((profile?['email'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text((profile!['email']).toString(), style: TextStyle(color: Colors.grey[700])),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          )
                        ],
                      ),
                    ),
                    // Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((profile?['bio'] ?? '').toString().isNotEmpty) ...[
                              Text('About', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text((profile!['bio']).toString()),
                              const SizedBox(height: 16),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Listings (${listings.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _ListingsGrid(listings: listings, onTap: widget.onListingTap),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
class _ListingsGrid extends StatelessWidget {
  final List<Listing> listings;
  final void Function(Listing listing)? onTap;
  const _ListingsGrid({required this.listings, this.onTap});

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final lower = path.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return path;
    try {
      return SupabaseHelper.client.storage.from('listings').getPublicUrl(path);
    } catch (_) {
      return path; // best effort
    }
  }

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Text('No listings yet', style: TextStyle(color: Colors.grey[600])),
      );
    }

    final crossAxisCount = MediaQuery.of(context).size.width > 700 ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3/4,
      ),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final l = listings[index];
        final cover = l.images.isNotEmpty ? _imageUrl(l.images.first) : '';
        final showPrice = l.price > 0.0; // hide if not set
        return MouseRegion(
          cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: InkWell(
            onTap: onTap != null ? () => onTap!(l) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColor.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 4/3,
                    child: cover.isNotEmpty
                        ? Image.network(cover, fit: BoxFit.cover)
                        : Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.image, color: Colors.grey))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(l.timeAgo, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          ],
                        ),
                        if (showPrice) ...[
                          const SizedBox(height: 6),
                          Text(l.formattedPrice, style: TextStyle(color: AppColor.primary, fontWeight: FontWeight.w700)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UserData {
  final Map<String, dynamic>? profile;
  final List<Listing> listings;
  final String displayName;
  final int totalListings;
  final int totalViews;
  final int totalLikes;
  _UserData({required this.profile, required this.listings, this.displayName = '', this.totalListings = 0, this.totalViews = 0, this.totalLikes = 0});
  factory _UserData.empty() => _UserData(profile: null, listings: const [], displayName: '', totalListings: 0, totalViews: 0, totalLikes: 0);
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
        ],
      ),
    );
  }
}
