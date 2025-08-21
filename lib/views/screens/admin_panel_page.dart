import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/model/listing.dart';
import '../../core/services/listing_service.dart';
import '../../core/model/user.dart';
import '../../constant/app_color.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text('Admin Panel', style: TextStyle(fontSize: 18)), // Smaller title
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 40, // Smaller app bar
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SvgPicture.asset(
              'assets/icons/iibsashologo.svg',
              height: 24, // Smaller logo
              width: 24,
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Listing>>(
        stream: ListingService.getListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No listings found.'));
          }
          final listings = snapshot.data!;
          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(listing.title, style: TextStyle(color: AppColor.textBlack)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listing.description, style: TextStyle(color: AppColor.textDark.withOpacity(0.7))),
                      SizedBox(height: 4),
                      Text('\$${listing.price.toStringAsFixed(0)}', style: TextStyle(color: AppColor.primary)),
                      SizedBox(height: 4),
                      Text('Category: ${listing.category}', style: TextStyle(fontSize: 12)),
                      SizedBox(height: 4),
                      FutureBuilder<AppUser?>(
                        future: AppUser.fetchById(listing.userId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text('Loading seller info...', style: TextStyle(fontSize: 12));
                          }
                          if (!snapshot.hasData || snapshot.data == null) {
                            return Text('Seller info not available', style: TextStyle(fontSize: 12));
                          }
                          final user = snapshot.data!;
                          return Text('Seller: ${user.name} (${user.email})', style: TextStyle(fontSize: 12));
                        },
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Remove Listing'),
                          content: Text('Are you sure you want to remove this listing?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('Remove', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ListingService.deleteListing(listing.id);
                        setState(() {});
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
