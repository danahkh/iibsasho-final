import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DummySearchWidget1 extends StatelessWidget {
  final VoidCallback onTap;

  const DummySearchWidget1({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 32, // Smaller height
        margin: EdgeInsets.only(top: 12), // Less top margin
        padding: EdgeInsets.only(left: 10), // Less padding
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), // Smaller radius
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.only(right: 8), // Less margin
              child: SvgPicture.asset(
                'assets/icons/Search.svg',
                color: Colors.black,
                width: 16, // Smaller icon
                height: 16,
              ),
            ),
            Text(
              'Find a product...',
              style: TextStyle(color: Colors.grey, fontSize: 13), // Smaller font
            ),
          ],
        ),
      ),
    );
  }
}
