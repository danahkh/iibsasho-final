import 'package:flutter/material.dart';
import '../constant/app_color.dart';

class AppLogoWidget extends StatelessWidget {
  final double? height;
  final double? width;
  final Color? color;
  final bool useThemeColor;
  final bool isWhiteVersion;
  final double? fontSize;

  const AppLogoWidget({
    super.key,
    this.height = 32,
    this.width,
    this.color,
    this.useThemeColor = true,
    this.isWhiteVersion = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the color based on context and parameters
    Color logoColor;
    if (color != null) {
      logoColor = color!;
    } else if (isWhiteVersion) {
      logoColor = Colors.white;
    } else if (useThemeColor) {
      logoColor = AppColor.primary;
    } else {
      logoColor = AppColor.primary;
    }

    // Calculate font size based on height if not provided
    double textSize = fontSize ?? (height != null ? height! * 0.5 : 16);

    return Container(
      height: height,
      width: width,
      child: Center(
        child: Text(
          'iibsasho',
          style: TextStyle(
            color: logoColor,
            fontSize: textSize,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

// Alternative logo widget for different scenarios
class AppLogoBranded extends StatelessWidget {
  final double? height;
  final double? width;
  final bool showText;
  final Color? logoColor;
  final Color? textColor;

  const AppLogoBranded({
    super.key,
    this.height = 32,
    this.width = 32,
    this.showText = false,
    this.logoColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final defaultLogoColor = logoColor ?? 
      (brightness == Brightness.dark ? AppColor.textLight : AppColor.primary);
    final defaultTextColor = textColor ?? 
      (brightness == Brightness.dark ? AppColor.textLight : AppColor.textDark);

    if (!showText) {
      return AppLogoWidget(
        height: height,
        width: width,
        color: defaultLogoColor,
        useThemeColor: false,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogoWidget(
          height: height,
          width: width,
          color: defaultLogoColor,
          useThemeColor: false,
        ),
        SizedBox(width: 8),
        Text(
          'iibsasho',
          style: TextStyle(
            color: defaultTextColor,
            fontSize: (height ?? 32) * 0.6,
            fontWeight: FontWeight.bold,
            fontFamily: 'poppins',
          ),
        ),
      ],
    );
  }
}
