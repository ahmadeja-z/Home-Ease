import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:homeease/widgets/image_gallery_viewer.dart';

class EcommerceBanner extends StatefulWidget {
  const EcommerceBanner({
    super.key,
    required this.imageUrls,
    this.height = 200.0, // Default height
    this.autoPlay =
        true, // Auto-scroll through images (ignored if only one image)
    this.autoPlayInterval = const Duration(seconds: 3),
    this.dotSize = 8.0, // Size of pagination dots
    this.activeDotColor = Colors.blue, // Color of active dot
    this.inactiveDotColor = Colors.grey, // Color of inactive dots
    this.borderRadius = 10.0, // Corner radius of the banner
    this.titleText, // Optional title text for the banner
    this.isImageTap = false, // Callback when an image is tapped
  });

  final List<String> imageUrls; // List of image URLs to display
  final double height; // Height of the banner
  final bool autoPlay; // Whether to auto-scroll (overridden if only one image)
  final Duration autoPlayInterval; // Interval for auto-scrolling
  final double dotSize; // Size of pagination dots
  final Color activeDotColor; // Color for the active dot
  final Color inactiveDotColor; // Color for inactive dots
  final double borderRadius; // Corner radius of the banner
  final List<String>? titleText;
  final bool? isImageTap; // Callback when an image is tapped

  @override
  State<EcommerceBanner> createState() => _EcommerceBannerState();
}

class _EcommerceBannerState extends State<EcommerceBanner> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool effectiveAutoPlay =
        widget.imageUrls.length > 1 && widget.autoPlay;

    return Column(
      children: [
        widget.imageUrls.length > 1
            ? CarouselSlider(
                options: CarouselOptions(
                  height: widget.height,
                  viewportFraction: 1.0,
                  enlargeCenterPage: false,
                  autoPlay: effectiveAutoPlay,
                  autoPlayInterval: widget.autoPlayInterval,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
                items: widget.imageUrls.asMap().entries.map((entry) {
                  int index = entry.key;
                  String imageUrl = entry.value;

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      child: GestureDetector(
                        onTap: () {
                          if (widget.isImageTap == true) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageGalleryViewer(
                                  imageUrls: widget.imageUrls,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          }
                        },
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: widget.height,
                          color: Colors.black.withValues(alpha: 0.9),
                          colorBlendMode: BlendMode.dstATop,
                          placeholder: (context, url) => Center(
                            child: SpinKitThreeInOut(
                              color: Theme.of(context).colorScheme.primary,
                              size: 25,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )
            : _singleImage(),

        /// DOTS
        if (widget.imageUrls.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.imageUrls.asMap().entries.map((entry) {
              return Container(
                width: widget.dotSize,
                height: widget.dotSize,
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == entry.key
                      ? widget.activeDotColor
                      : widget.inactiveDotColor,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _singleImage() {
    return Container(
      height: widget.height,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: GestureDetector(
        onTap: () {
          if (widget.isImageTap == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ImageGalleryViewer(imageUrls: widget.imageUrls),
              ),
            );
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: CachedNetworkImage(
            imageUrl: widget.imageUrls[0],
            fit: BoxFit.cover,
            width: double.infinity,
            height: widget.height,
            color: Colors.black.withValues(alpha: 0.9),
            colorBlendMode: BlendMode.dstATop,
            placeholder: (context, url) => Center(
              child: SpinKitThreeInOut(
                color: Theme.of(context).colorScheme.primary,
                size: 25,
              ),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.error_outline, color: Colors.red, size: 40),
            ),
          ),
        ),
      ),
    );
  }
}
