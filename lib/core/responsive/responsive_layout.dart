import 'package:flutter/material.dart';
import 'responsive.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget tabletLayout;
  final Widget desktopLayout;

  const ResponsiveLayout({
    super.key,
    required this.mobileLayout,
    required this.tabletLayout,
    required this.desktopLayout,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return desktopLayout;
    } else if (Responsive.isTablet(context)) {
      return tabletLayout;
    } else {
      return mobileLayout;
    }
  }
}
