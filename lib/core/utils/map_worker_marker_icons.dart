import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeease/core/assets/app_images.dart';

/// Loads custom Google Maps marker bitmaps for online / assigned workers.
class MapWorkerMarkerIcons {
  MapWorkerMarkerIcons._();

  static BitmapDescriptor? online;
  static BitmapDescriptor? assigned;

  static Future<void> load(BuildContext context) async {
    online = await _loadIcon(
      context: context,
      assetPath: AppImages.mapWorkerIcon,
      fillColor: const Color(0xFF2E7D32),
    );
    assigned = await _loadIcon(
      context: context,
      assetPath: AppImages.mapWorkerIconAssigned,
      fillColor: const Color(0xFF1565C0),
    );
  }

  static Future<BitmapDescriptor> _loadIcon({
    required BuildContext context,
    required String assetPath,
    required Color fillColor,
  }) async {
    try {
      await DefaultAssetBundle.of(context).load(assetPath);
      return await BitmapDescriptor.asset(
        createLocalImageConfiguration(context, size: const Size(48, 48)),
        assetPath,
      );
    } catch (_) {
      return _createCanvasIcon(
        icon: Icons.engineering_rounded,
        fillColor: fillColor,
      );
    }
  }

  /// Draws a circular worker/service badge when no PNG asset is present.
  static Future<BitmapDescriptor> _createCanvasIcon({
    required IconData icon,
    required Color fillColor,
  }) async {
    const double size = 120;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center.translate(0, 2), size * 0.38, shadow);

    final ring = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.4, ring);

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.34, fill);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.34,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      width: 48,
      height: 48,
    );
  }
}
