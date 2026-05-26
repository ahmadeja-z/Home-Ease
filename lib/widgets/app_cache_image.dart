import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppCacheImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final Widget? imageFailWidget;
  final double? round;
  final bool? showNative;
  final double? opacity;
  final VoidCallback? onTap;
  final double? marginHorizontal;
  final double? marginVertical;
  final bool? showSpinKit;
  final BoxFit boxFit;

  const AppCacheImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.round,
    this.imageFailWidget,
    this.showNative,
    this.onTap,
    this.marginHorizontal,
    this.marginVertical,
    this.showSpinKit = false,
    this.opacity,
    this.boxFit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: marginHorizontal ?? 0,
          vertical: marginVertical ?? 0,
        ),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(round ?? 0),
          border: Border.all(color: Theme.of(context).colorScheme.onPrimary),

          boxShadow: const [
            // BoxShadow(
            //   //    color: Colors.transparent.withOpacity(opacity ?? 0.15),
            //   spreadRadius: 0,
            //   blurRadius: 5,
            //   offset: Offset(0, 7), // changes position of shadow
            // ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(round ?? 20),
          child: CachedNetworkImage(
            //memCacheWidth: width.toInt(),
            //memCacheHeight: height.toInt(),
            width: width,
            height: height,
            fit: boxFit,
            imageUrl: imageUrl,
            placeholder: (context, url) => SizedBox(
              width: width,
              height: height,
              child: NativeProgress(showNative: showNative ?? false),
            ),
            errorWidget: (context, url, error) => SizedBox(
              height: MediaQuery.of(context).size.height * 0.12,
              child:
                  imageFailWidget ??
                  const Icon(Icons.image, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}

class NativeProgress extends StatelessWidget {
  final bool showNative;
  final double? values;

  const NativeProgress({super.key, required this.showNative, this.values});

  @override
  Widget build(BuildContext context) {
    return Platform.isAndroid == true
        ? showNative
              ? Center(child: CircularProgressIndicator(value: values))
              : const CupertinoActivityIndicator()
        : Theme(
            data: ThemeData(
              cupertinoOverrideTheme: CupertinoThemeData(
                brightness: Brightness.light,
                primaryColor: Theme.of(context).colorScheme.onPrimary,
                barBackgroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            child: const CupertinoActivityIndicator(),
          );
  }
}
