import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget desktopBody;
  final int selectedIndex;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    required this.desktopBody,
    this.selectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return mobileBody;
        } else {
          return desktopBody;
        }
      },
    );
  }
}
