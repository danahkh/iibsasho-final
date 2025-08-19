import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constant/app_color.dart';
// Removed: import 'package:iibsasho/views/screens/cart_page.dart';
import 'package:iibsasho/views/screens/message_page.dart';
import 'package:iibsasho/views/widgets/custom_icon_button_widget.dart';
import '../../widgets/app_logo_widget.dart';

class MainAppBar extends StatefulWidget implements PreferredSizeWidget {
  // Removed: final int cartValue;
  final int chatValue;

  const MainAppBar({super.key, required this.chatValue});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  _MainAppBarState createState() => _MainAppBarState();
}

class _MainAppBarState extends State<MainAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
  automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent, // Transparent background
      elevation: 0,
  centerTitle: true,
      title: const AppLogoWidget(
        height: 28,
      ),
      actions: [
        // Keep right spacing consistent
        const SizedBox(width: 12),
        CustomIconButtonWidget(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => MessagePage()));
          },
          value: widget.chatValue,
          margin: EdgeInsets.only(left: 8),
          icon: SvgPicture.asset(
            'assets/icons/Chat.svg',
            color: AppColor.primary, // navy blue dark
          ),
        ),
      ],
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }
}
