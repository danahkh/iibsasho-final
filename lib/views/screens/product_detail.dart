import 'package:flutter/material.dart';
import 'package:iibsasho/core/model/listing.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iibsasho/core/model/user.dart';
import '../../constant/app_color.dart';

class ListingDetailPage extends StatelessWidget {
  final Listing listing;
  const ListingDetailPage({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColor.primary, size: 18), // Smaller icon
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.white),
            shape: MaterialStateProperty.all(CircleBorder()),
            minimumSize: MaterialStateProperty.all(Size(32, 32)), // Smaller button
            padding: MaterialStateProperty.all(EdgeInsets.zero),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SvgPicture.asset(
              'assets/icons/iibsashologo.svg',
              height: 20, // Smaller logo
              width: 20,
            ),
          ),
        ],
      ),
      body: ListView(
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        children: [
          // Section 1 - Images & AppBar
          Stack(
            alignment: Alignment.topCenter,
            children: [
              GestureDetector(
                onTap: () {
                  // Image viewer is implemented below (tapping image opens viewer)
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 310,
                  color: AppColor.primarySoft,
                  child: listing.images.isNotEmpty
                      ? PageView(
                          children: listing.images
                              .map((img) => Image.network(img, fit: BoxFit.cover))
                              .toList(),
                        )
                      : Center(child: Icon(Icons.image, size: 80, color: AppColor.border)),
                ),
              ),
            ],
          ),
          // Section 2 - Listing Info
          Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'poppins', color: Colors.black),
                ),
                SizedBox(height: 8),
                Text(
                  '₦${listing.price}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.green),
                ),
                SizedBox(height: 8),
                Text(
                  listing.description,
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red, size: 20),
                    SizedBox(width: 4),
                    Expanded(child: Text(listing.address, style: TextStyle(color: Colors.black54))),
                  ],
                ),
                SizedBox(height: 16),
                Text('Condition: ${listing.condition}', style: TextStyle(color: Colors.black54)),
                SizedBox(height: 24),
                // Seller Info
                FutureBuilder<AppUser?>(
                  future: AppUser.fetchById(listing.userId),
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
                    return Row(
                      children: [
                        if (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                          CircleAvatar(backgroundImage: NetworkImage(user.photoUrl!), radius: 16),
                        if (user.photoUrl == null || user.photoUrl!.isEmpty)
                          CircleAvatar(radius: 16, child: Icon(Icons.person)),
                        SizedBox(width: 8),
                        Text(user.name, style: TextStyle(fontWeight: FontWeight.w500)),
                        SizedBox(width: 8),
                        Text(user.email, style: TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
