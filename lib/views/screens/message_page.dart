import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constant/app_color.dart';
import 'package:iibsasho/core/model/Message.dart';
import 'package:iibsasho/views/widgets/message_tile_widget.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});
  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  List<Message> listMessage = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            Text('Message', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
            Text('1 Unreaded', style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.7))),
          ],
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: SvgPicture.asset('assets/icons/Arrow-left.svg', color: AppColor.primary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SvgPicture.asset(
              'assets/icons/iibsashologo.svg',
              height: 32,
              width: 32,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            width: MediaQuery.of(context).size.width,
            color: AppColor.primarySoft,
          ),
        ), systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: listMessage.isEmpty
          ? Center(child: Text('No messages yet.'))
          : ListView(
              shrinkWrap: true,
              physics: BouncingScrollPhysics(),
              children: List.generate(listMessage.length, (index) {
                return MessageTileWidget(data: listMessage[index]);
              }),
            ),
    );
  }
}
