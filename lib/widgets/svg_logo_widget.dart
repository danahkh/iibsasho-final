import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constant/app_color.dart';

class SvgLogoWidget extends StatelessWidget {
  final double? height;
  final double? width;

  const SvgLogoWidget({
    super.key,
    this.height = 32,
    this.width = 32,
  });

  @override
  Widget build(BuildContext context) {
    // Simple, stable SVG loading without FutureBuilder to prevent blinking
    return SvgPicture.asset(
      'assets/icons/A_logo_design_displayed_in_off-white_against_a_tra.svg',
      height: height,
      width: width,
      fit: BoxFit.contain,
      // Only show placeholder if SVG completely fails to load
      placeholderBuilder: (context) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            'iib',
            style: TextStyle(
              color: AppColor.primary,
              fontWeight: FontWeight.bold,
              fontSize: (height ?? 32) * 0.4,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}
