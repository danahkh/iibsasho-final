import 'package:flutter/material.dart';
import '../../constant/app_color.dart';

class FlashsaleCountdownTile extends StatelessWidget {
  final String digit;

  const FlashsaleCountdownTile({super.key, required this.digit});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Text(
          digit,
          style: TextStyle(
            color: AppColor.primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
