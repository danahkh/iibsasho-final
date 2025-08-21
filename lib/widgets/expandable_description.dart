import 'package:flutter/material.dart';
import '../constant/app_color.dart';

class ExpandableDescription extends StatefulWidget {
  final String description;
  final int maxLines;
  final int maxLength;

  const ExpandableDescription({
    super.key,
    required this.description,
    this.maxLines = 3,
    this.maxLength = 150,
  });

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool isLongDescription = widget.description.length > widget.maxLength;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: Text(
            widget.description,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              height: 1.5,
            ),
            maxLines: isExpanded ? null : widget.maxLines,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          secondChild: Text(
            widget.description,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          crossFadeState: isExpanded 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
          duration: Duration(milliseconds: 300),
        ),
        if (isLongDescription) ...[
          SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Row(
              children: [
                Text(
                  isExpanded ? 'See less' : 'See more',
                  style: TextStyle(
                    color: AppColor.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  isExpanded 
                      ? Icons.keyboard_arrow_up 
                      : Icons.keyboard_arrow_down,
                  color: AppColor.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}