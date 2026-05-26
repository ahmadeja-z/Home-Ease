import 'package:flutter/material.dart';

import '../core/assets/font_family.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.action,
    this.requireBackButton = true,
    this.backgroundColor,
    this.backIcon = Icons.arrow_back_sharp,
    this.elevation = 0.0,
  });

  final String title;
  final Widget? action;
  final bool requireBackButton;
  final Color? backgroundColor;
  final IconData backIcon;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Define breakpoints
        final screenWidth = MediaQuery.of(context).size.width;
        final bool isMobile = screenWidth < 600;
        final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
        final bool isLargeTablet = screenWidth >= 1024;

        // Responsive values
        final double horizontalPadding = isMobile ? 8 : (isTablet ? 16 : 24);
        final double iconSize = isMobile ? 22 : (isTablet ? 24 : 26);
        final double titleFontSize = isMobile ? 19 : (isTablet ? 21 : 23);
        final double backButtonSize = isMobile ? 40 : (isTablet ? 44 : 48);
        final double borderRadius = isMobile ? 12 : (isTablet ? 14 : 16);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor ?? Theme.of(context).colorScheme.onPrimary,
                (backgroundColor ?? Theme.of(context).colorScheme.onPrimary)
                    .withValues(alpha: 0.95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.shadow.withValues(alpha: 0.08),
                offset: const Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: !isLargeTablet, // Left align on large tablets
            elevation: elevation,
            leading: requireBackButton
                ? Container(
                    margin: EdgeInsets.only(left: horizontalPadding),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(borderRadius),
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: backButtonSize,
                          height: backButtonSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadius),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            backIcon,
                            color: Theme.of(context).colorScheme.onSecondary,
                            size: iconSize,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            title: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Theme.of(
                    context,
                  ).colorScheme.onSecondary.withValues(alpha: 0.95),
                  Theme.of(
                    context,
                  ).colorScheme.onSecondary.withValues(alpha: 0.85),
                ],
              ).createShader(bounds),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: FontFamily.fontsPoppinsSemiBold,
                  fontSize: titleFontSize,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: horizontalPadding),
                child: action ?? const SizedBox.shrink(),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
