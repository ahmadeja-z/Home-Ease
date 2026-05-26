import 'package:flutter/material.dart';
import '../assets/font_family.dart';

class SnackBarHelper {
  static void showTopSnackBar({
    required BuildContext context,
    required String title,
    required String subtitle,
    Color backgroundColor = Colors.green,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    final width = isDesktop ? screenWidth * 0.5 : screenWidth - 40;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 20,
        left: 20,
        child: SlideInSnackBar(
          width: width,
          title: title,
          subtitle: subtitle,
          backgroundColor: backgroundColor,
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  static void showSuccess(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    showTopSnackBar(
      context: context,
      title: title,
      subtitle: subtitle,
      backgroundColor: Theme.of(context).colorScheme.secondary,
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    showTopSnackBar(
      context: context,
      title: title,
      subtitle: subtitle,
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }
}

class SlideInSnackBar extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final double width;

  const SlideInSnackBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.width,
  });

  @override
  State<SlideInSnackBar> createState() => _SlideInSnackBarState();
}

class _SlideInSnackBarState extends State<SlideInSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _offset = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offset,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black.withOpacity(.15),
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: FontFamily.fontsPoppinsRegular,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: FontFamily.fontsPoppinsRegular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}