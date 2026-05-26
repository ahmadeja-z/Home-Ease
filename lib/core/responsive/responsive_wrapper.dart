import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ResponsiveWrapperWidget extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapperWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBreakpoints.builder(
      child: child,
      breakpoints: const [
        Breakpoint(start: 0, end: 600, name: MOBILE),
        Breakpoint(start: 601, end: 900, name: TABLET),
        Breakpoint(start: 901, end: 1200, name: DESKTOP),
        Breakpoint(start: 1201, end: double.infinity, name: '4K'),
      ],
    );
  }
}
