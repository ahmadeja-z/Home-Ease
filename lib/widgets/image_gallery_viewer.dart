import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:homeease/core/assets/app_images.dart';
import 'package:homeease/core/assets/font_family.dart';
import 'package:photo_view/photo_view.dart';

class ImageGalleryViewer extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageGalleryViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("No images found", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return BlocProvider(
      create: (_) => ImageGalleryCubit()..changeImage(initialIndex),
      child: _GalleryBody(imageUrls: imageUrls, initialIndex: initialIndex),
    );
  }
}

class _GalleryBody extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _GalleryBody({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ImageGalleryCubit>();
    final pageController = PageController(initialPage: initialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        actions: [
          BlocBuilder<ImageGalleryCubit, int>(
            builder: (context, state) => Text(
              "${cubit.state + 1} / ${imageUrls.length}",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontFamily: FontFamily.fontsPoppinsRegular,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
        centerTitle: true,

        title: Image.asset(
          Theme.of(context).brightness == Brightness.dark
              ? AppImages.homeEaseDarkLogo
              : AppImages.homeEaseLogo,
          width: 100,
          height: 30,
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: imageUrls.length,
              onPageChanged: cubit.changeImage,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onVerticalDragUpdate: (details) {
                    // If dragging down
                    if (details.primaryDelta != null &&
                        details.primaryDelta! > 20) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: PhotoView(
                    imageProvider: CachedNetworkImageProvider(imageUrls[index]),
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2.5,
                  ),
                );
              },
            ),
          ),
          if (imageUrls.length > 1)
            SizedBox(
              height: 100,
              child: BlocBuilder<ImageGalleryCubit, int>(
                builder: (context, selectedIndex) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          cubit.changeImage(index);
                          pageController.jumpToPage(index);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(5),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedIndex == index
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: imageUrls[index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class ImageGalleryCubit extends Cubit<int> {
  ImageGalleryCubit() : super(0);

  void changeImage(int index) => emit(index);
}
