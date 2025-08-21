import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constant/app_color.dart';
import 'login_page.dart';
import 'supabase_test_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Section 1 - Logo
            Container(
              margin: EdgeInsets.only(top: 32),
              width: 120,
              height: 120,
              child: SvgPicture.asset('assets/icons/iibsashologo.svg'),
            ),
            // Section 1b - Illustration
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: SvgPicture.asset('assets/icons/shopping illustration.svg'),
            ),
            // Section 2 - Iibsasho with Caption
            Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Iibsasho',
                    style: TextStyle(
                      color: AppColor.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                      fontFamily: 'poppins',
                    ),
                  ),
                ),
                Text(
                  'Market in your pocket. Find \nyour best outfit here.',
                  style: TextStyle(color: AppColor.textDark.withOpacity(0.7), fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            // Section 3 - Get Started Button and Test Button
            Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.symmetric(horizontal: 16),
              margin: EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18), 
                      backgroundColor: AppColor.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      'Get Started',
                      style: TextStyle(color: AppColor.textLight, fontWeight: FontWeight.w600, fontSize: 18, fontFamily: 'poppins'),
                    ),
                  ),
                  SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => SupabaseTestPage()));
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                      side: BorderSide(color: AppColor.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Test Database Connection',
                      style: TextStyle(color: AppColor.primary, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
