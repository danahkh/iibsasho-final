import 'package:flutter/material.dart';
import '../constant/app_color.dart';
import 'custom_bottom_nav.dart';

/// Standard app scaffold with blue header (AppBar) and universal bottom nav.
/// Excludes admin dashboard which should build its own Scaffold.
class StandardScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final int currentIndex; // index for bottom nav highlighting
  final Function(int)? onTabChange;
  final bool showBack;
  final Color? backgroundColor;
  final Widget? floatingActionButton;

  const StandardScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.bottom,
    this.currentIndex = 4,
    this.onTabChange,
    this.showBack = true,
    this.backgroundColor,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColor.background,
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        backgroundColor: AppColor.primary,
        elevation: 2,
        leading: showBack ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()) : null,
        actions: actions,
        bottom: bottom,
      ),
      body: body,
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i){
          if (onTabChange != null) {
            onTabChange!(i);
          } else {
            // Default: pop until root then maybe switch
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        },
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
