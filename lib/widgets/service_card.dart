import 'package:flutter/material.dart';
import 'package:homeease/presentation/home/services_details_screen.dart';
import 'package:homeease/widgets/app_cache_image.dart';

import '../core/utils/currency_icon.dart';
import '../models/services_model.dart';

class ServiceCard extends StatelessWidget {
  final ServicesModel service;

  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing
    final isSmall = screenWidth < 360;
    final imageHeight = isSmall ? 110.0 : 130.0;
    final titleFontSize = isSmall ? 12.0 : 14.0;
    final priceFontSize = isSmall ? 15.0 : 17.0;

    final showFixedPrice = service.showFixedPrice;
    final displayPrice =
        showFixedPrice ? service.fixedJobRate! : service.perHourRate;
    final priceSuffix = showFixedPrice ? ' fixed' : '/hr';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServicesDetailsScreen(service: service),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSecondary.withValues(alpha: 0.06),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: colorScheme.onSecondary.withValues(alpha: 0.04),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image Section ──────────────────────────────────────────────
              Stack(
                children: [
                  // Hero Image
                  SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: service.mainImage != null
                        ? AppCacheImage(
                            imageUrl: service.mainImage!,
                            width: double.infinity,
                            height: imageHeight,
                            boxFit: BoxFit.cover,
                            round: 0,
                          )
                        : Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 36,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ),
                  ),
      
                  // Gradient Overlay — subtle depth at the bottom of the image
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
      
                  // Rating Badge — top left
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _RatingBadge(rating: service.rating),
                  ),
      
                 
                ],
              ),
      
              // ── Details Section ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(alignment: Alignment.centerRight, child: Text(service.categoryTitle ?? '', style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.2),)),
                    // Title
                    SizedBox(height: 4,),
                    Text(
                      service.title,
                      style: TextStyle(
                        color: colorScheme.onSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: titleFontSize,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
      
                    const SizedBox(height: 5),
      
                    // Price Row — fixed job rate or per hour
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${CurrencyIcon.currencyIcon}${displayPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: priceFontSize,
                            letterSpacing: -0.4,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1.5),
                          child: Text(
                            priceSuffix,
                            style: TextStyle(
                              color: colorScheme.onSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const Spacer(),
      
                        // CTA Arrow Button
                        _ArrowButton(colorScheme: colorScheme),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting Sub-Widgets ──────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 13),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}


class _ArrowButton extends StatelessWidget {
  final ColorScheme colorScheme;
  const _ArrowButton({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 16,
        color: colorScheme.onPrimary,
      ),
    );
  }
  
}