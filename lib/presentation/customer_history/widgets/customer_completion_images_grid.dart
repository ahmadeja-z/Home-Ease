import 'package:flutter/material.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_section_card.dart';
import 'package:homeease/widgets/app_cache_image.dart';
import 'package:homeease/widgets/image_gallery_viewer.dart';

class CustomerCompletionImagesGrid extends StatelessWidget {
  final List<String> imageUrls;
  final String? completionNote;

  const CustomerCompletionImagesGrid({
    super.key,
    required this.imageUrls,
    this.completionNote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImages = imageUrls.isNotEmpty;
    final hasNote =
        completionNote != null && completionNote!.trim().isNotEmpty;

    return CustomerHistorySectionCard(
      title: 'Completion report',
      icon: Icons.photo_library_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasNote) ...[
            Text(
              'Worker note',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(completionNote!),
            const SizedBox(height: 12),
          ],
          if (hasImages) ...[
            Text(
              'Completion images',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                final url = imageUrls[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
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
                      imageUrl: url,
                      width: double.infinity,
                      height: double.infinity,
                      boxFit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ] else
            Text(
              'No completion images submitted',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
