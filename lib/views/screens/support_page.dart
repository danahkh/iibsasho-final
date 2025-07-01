import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

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
            Text('Support'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(child: Text('Support and help resources will appear here.')),
    );
  }
}
