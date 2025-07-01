import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constant/app_color.dart';
import 'package:iibsasho/core/model/Notification.dart';
import 'package:iibsasho/core/services/NotificationService.dart';
import 'package:iibsasho/views/widgets/main_app_bar_widget.dart';
import 'package:iibsasho/views/widgets/menu_tile_widget.dart';
import 'package:iibsasho/views/widgets/notification_tile.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<UserNotification> listNotification = NotificationService.listNotification;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: MainAppBar(
        chatValue: 2,
      ),
      body: ListView(
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        children: [
          // Section 1 - Menu
          MenuTileWidget(
            onTap: () {},
            icon: SvgPicture.asset(
              'assets/icons/Info Square.svg',
              color: AppColor.secondary.withOpacity(0.5),
            ),
            title: 'Iibsasho Info',
            subtitle: 'Lorem ipsum Dolor sit Amet',
          ),
          // Section 2 - Status ( LIST )
          Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.builder(
                  itemBuilder: (context, index) {
                    return NotificationTile(
                      data: listNotification[index],
                      onTap: () {},
                    );
                  },
                  itemCount: listNotification.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
