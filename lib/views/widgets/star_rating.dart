import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color color;
  final void Function(double)? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 20,
    this.color = Colors.amber,
    this.onRatingChanged,
  });

  Widget buildStar(BuildContext context, int index) {
    IconData icon;
    if (index >= rating) {
      icon = Icons.star_border;
    } else if (index > rating - 1 && index < rating) {
      icon = Icons.star_half;
    } else {
      icon = Icons.star;
    }
    return GestureDetector(
      onTap: onRatingChanged != null ? () => onRatingChanged!(index + 1.0) : null,
      child: Icon(
        icon,
        color: color,
        size: size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) => buildStar(context, index)),
    );
  }
}
