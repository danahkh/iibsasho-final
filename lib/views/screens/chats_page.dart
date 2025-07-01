import 'package:flutter/material.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(
              height: 32,
              width: 32,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.asset('assets/icons/iibsashologo.svg', package: null),
              ),
            ),
            Text('Chats'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(child: Text('Your chats will appear here.')),
    );
  }
}
