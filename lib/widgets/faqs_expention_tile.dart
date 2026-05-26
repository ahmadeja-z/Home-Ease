import 'package:flutter/material.dart';
import 'package:homeease/core/utils/media_querry_extention.dart';

import '../core/assets/font_family.dart';
import '../presentation/faqs/faqs_screen.dart';

class PremiumFaqTile extends StatelessWidget {
  final Faq faq;
  final bool isExpanded;
  final Animation<double> animation;
  final VoidCallback onTap;

  const PremiumFaqTile({
    super.key,
    required this.faq,
    required this.isExpanded,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpanded
                  ? primaryColor.withOpacity(0.3)
                  : theme.colorScheme.outline.withOpacity(0.1),
              width: isExpanded ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isExpanded
                    ? primaryColor.withOpacity(0.1)
                    : Colors.black.withOpacity(0.03),
                blurRadius: isExpanded ? 12 : 6,
                offset: Offset(0, isExpanded ? 4 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              splashColor: primaryColor.withOpacity(0.05),
              highlightColor: primaryColor.withOpacity(0.02),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        // Icon with subtle background
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOutCubic,
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isExpanded
                                ? primaryColor.withOpacity(0.12)
                                : primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            faq.icon,
                            color: isExpanded
                                ? primaryColor
                                : primaryColor.withOpacity(0.7),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Question text
                        Expanded(
                          child: Text(
                            faq.question ?? '',
                            style: TextStyle(
                              fontFamily: FontFamily.fontsPoppinsSemiBold,
                              fontSize: context.scaledFont(14.5),
                              color: theme.colorScheme.onSecondary,
                              height: 1.4,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Animated chevron
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOutCubic,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isExpanded
                                  ? primaryColor.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: isExpanded
                                  ? primaryColor
                                  : theme.colorScheme.outline,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Answer section with smooth animation
                  SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: FadeTransition(
                          opacity: animation,
                          child: Text(
                            faq.answer ?? '',
                            style: TextStyle(
                              fontFamily: FontFamily.fontsPoppinsRegular,
                              fontSize: context.scaledFont(13),
                              color: theme.colorScheme.onSecondary.withOpacity(
                                0.75,
                              ),
                              height: 1.65,
                              letterSpacing: 0.15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
