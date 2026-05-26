import 'package:flutter/material.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/core/utils/currency_icon.dart';
import 'package:homeease/models/services_model.dart';
import 'package:homeease/presentation/scheduled_booking/screens/scheduled_booking_screen.dart';
import 'package:homeease/widgets/app_cache_image.dart';
import 'package:homeease/widgets/image_gallery_viewer.dart';
class ServicesDetailsScreen extends StatelessWidget {
  final ServicesModel service;

  const ServicesDetailsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [ 
          _buildSliverAppBar(context,  ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(context),
                  const SizedBox(height: 20),
                  _buildQuickStats(context),
                  const SizedBox(height: 24),
                  _buildSectionLabel(theme, 'Description'),
                  const SizedBox(height: 10),
                  _buildDescriptionCard(context),
                  if (service.location != null &&
                      service.location!.trim().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionLabel(theme, 'Location'),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      context: context,
                      icon: Icons.location_on_outlined,
                      iconColor: Theme.of(context).colorScheme.secondary,
                      child: Text(
                        service.location!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  if (service.extraImages.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionLabel(theme, 'Gallery'),
                    const SizedBox(height: 12),
                    _buildGallery(context),
                  ],
                  if (service.toolsIncluded.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionLabel(theme, 'Tools included'),
                    const SizedBox(height: 12),
                    _buildToolsList(context),
                  ],
                  if (service.note != null && service.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionLabel(theme, 'Note'),
                    const SizedBox(height: 10),
                    _buildNoteCard(context),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, theme),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
  
  ) {
    final hasImage =
        service.mainImage != null && service.mainImage!.trim().isNotEmpty;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Center(
          child: Material(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              AppCacheImage(
                imageUrl: service.mainImage!,
                width: double.infinity,
                height: double.infinity,
                boxFit: BoxFit.cover,
                round: 0,
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                      AppTheme.mainDarkColor,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.home_repair_service_rounded,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (service.categoryTitle != null &&
                      service.categoryTitle!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withValues(
                          alpha: 0.9,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        service.categoryTitle!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    service.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 8,
                        ),
                      ],
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

  Widget _buildTitleSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.title,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              if (service.categoryTitle != null &&
                  service.categoryTitle!.isNotEmpty)
                Text(
                  service.categoryTitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildActiveChip(context),
            const SizedBox(height: 8),
            _buildPricingTypeChip(context),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingTypeChip(BuildContext context) {
    final isFixed = service.showFixedPrice;
    final color = isFixed
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFixed ? Icons.price_check_rounded : Icons.schedule_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            isFixed ? 'Fixed price' : 'Per hour',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChip(BuildContext context) {
    final active = service.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (active ? AppTheme.successColor : AppTheme.errorColor)
            .withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? AppTheme.successColor : AppTheme.errorColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: active ? AppTheme.successColor : AppTheme.errorColor,
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    if (service.showFixedPrice) {
      return Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.price_check_rounded,
              label: 'Fixed price',
              value:
                  '${CurrencyIcon.currencyIcon}${service.fixedJobRate!.toStringAsFixed(0)}',
              accent: primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.work_outline_rounded,
              label: 'Job type',
              value: 'Fixed',
              accent: secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.star_rounded,
              label: 'Rating',
              value: service.rating > 0
                  ? service.rating.toStringAsFixed(1)
                  : 'New',
              accent: AppTheme.rattingYellow,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.payments_outlined,
            label: 'Per hour',
            value:
                '${CurrencyIcon.currencyIcon}${service.perHourRate.toStringAsFixed(0)}',
            accent: primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.schedule_rounded,
            label: 'Minimum',
            value: '${service.minimumHours.toStringAsFixed(1)} hrs',
            accent: secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.star_rounded,
            label: 'Rating',
            value: service.rating > 0
                ? service.rating.toStringAsFixed(1)
                : 'New',
            accent: AppTheme.rattingYellow,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    return _buildInfoCard(
      context: context,
      icon: Icons.description_outlined,
      iconColor: Theme.of(context).colorScheme.primary,
      child: Text(
        service.description.trim().isEmpty
            ? 'No description provided.'
            : service.description,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
      ),
    );
  }

  Widget _buildGallery(BuildContext context,) {
    final urls = service.extraImages.map((e) => e.url).where((u) => u.isNotEmpty).toList();

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageGalleryViewer(
                    imageUrls: urls,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 112,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppCacheImage(
                      imageUrl: urls[index],
                      width: 112,
                      height: 112,
                      boxFit: BoxFit.cover,
                      round: 0,
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Icon(
                        Icons.zoom_in_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolsList(BuildContext context) {
    return Column(
      children: service.toolsIncluded.map((tool) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
            ),
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.build_circle_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${tool.quantity}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _IncludedBadge(included: tool.isIncluded, context: context),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoteCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppTheme.accentColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              service.note!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ThemeData theme) {
    final showFixed = service.showFixedPrice;
    final estimatedMin = service.perHourRate * service.minimumHours;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  showFixed
                      ? '${CurrencyIcon.currencyIcon}${service.fixedJobRate!.toStringAsFixed(0)} fixed price'
                      : 'From ${CurrencyIcon.currencyIcon}${service.perHourRate.toStringAsFixed(0)}/hr',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  showFixed
                      ? 'One-time fixed job · no hourly billing'
                      : 'Min. ${service.minimumHours.toStringAsFixed(1)} hrs · ~${CurrencyIcon.currencyIcon}${estimatedMin.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: service.isActive
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ScheduledBookingScreen(service: service),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.calendar_month_rounded, size: 20),
            label: const Text('Book now'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildInfoCard({

    required IconData icon,
    required Color iconColor,
    required Widget child,
    required BuildContext context,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
        ),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }

}

class _StatTile extends StatelessWidget {
   
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _StatTile({
 
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _IncludedBadge extends StatelessWidget {
  final bool included;
  final BuildContext context;

  const _IncludedBadge({required this.included, required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (included ? AppTheme.successColor : Theme.of(context).colorScheme.outline)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        included ? 'Included' : 'Extra',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: included ? AppTheme.successColor : Theme.of(context).hintColor,
        ),
      ),
    );
  }
}
