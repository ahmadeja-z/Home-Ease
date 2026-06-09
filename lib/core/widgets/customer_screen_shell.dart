import 'package:flutter/material.dart';
import 'package:homeease/core/widgets/network_status_banner.dart';

/// Banner wrapper for customer screens outside the navbar (pushed routes).
class CustomerScreenShell extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const CustomerScreenShell({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Column(
        children: [
          const NetworkStatusBanner(),
          Expanded(child: body),
        ],
      ),
    );
  }
}
