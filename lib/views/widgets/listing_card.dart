import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../core/model/listing.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPromoted = listing.isPromoted;
    final bool isFeatured = listing.isFeatured && !isPromoted; // promoted overrides featured visuals

  final borderColor = isPromoted
    ? Colors.amber.shade600
    : isFeatured
      ? AppColor.accent // blue border for featured
      : Colors.transparent;
    final gradient = isPromoted
        ? LinearGradient(colors: [Colors.amber.shade400, Colors.amber.shade700])
        : null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: isPromoted ? 2.5 : (isFeatured ? 2 : 0.5),
        ),
        gradient: gradient,
        boxShadow: [
          if (isPromoted)
            BoxShadow(
              color: Colors.amber.withOpacity(0.35),
              blurRadius: 14,
              offset: Offset(0, 6),
            )
          else if (isFeatured)
            BoxShadow(
              color: AppColor.accent.withOpacity(0.18),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
              // Image preview
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColor.primarySoft,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: listing.images.isNotEmpty
                      ? Image.network(
                          listing.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColor.primarySoft,
                              child: Icon(Icons.image, color: AppColor.border, size: 32),
                            );
                          },
                        )
                      : Icon(Icons.image, color: AppColor.border, size: 32),
                ),
              ),
              SizedBox(width: 12),
              // Listing details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isPromoted)
                          _buildTag('PROMOTED', Colors.black87, Colors.amberAccent)
                        else if (isFeatured)
                          _buildTag('FEATURED', Colors.white, AppColor.accent),
                      ],
                    ),
                    if (isPromoted || isFeatured) SizedBox(height: 4),
                    Text(
                      listing.title,
                      style: TextStyle(
                        color: AppColor.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '\$${listing.price}',
                      style: TextStyle(
                        color: AppColor.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.red),
                        SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            listing.location,
                            style: TextStyle(
                              color: AppColor.placeholder,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColor.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        listing.category,
                        style: TextStyle(
                          color: AppColor.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color textColor, Color bg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
