import 'package:flutter/material.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_section_card.dart';
import 'package:homeease/widgets/app_cache_image.dart';
import 'package:homeease/widgets/image_gallery_viewer.dart';

class ScheduledRequestImagesGrid extends StatelessWidget {
  final List<String> imageUrls;
  final String title;

  const ScheduledRequestImagesGrid({
    super.key,
    required this.imageUrls,
    this.title = 'Your issue photos',
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return CustomerHistorySectionCard(
        title: title,
        icon: Icons.photo_library_outlined,
        child: Text(
          'No photos attached',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).hintColor,
              ),
        ),
      );
    }

    return CustomerHistorySectionCard(
      title: title,
      icon: Icons.photo_library_outlined,
      child: SizedBox(
        height: 88,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: imageUrls.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ImageGalleryViewer(
                      imageUrls: imageUrls,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AppCacheImage(
                  imageUrl: imageUrls[index],
                  width: 88,
                  height: 88,
                  boxFit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
