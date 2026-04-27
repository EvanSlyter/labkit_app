import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';   // <-- needed for GlobalKey, BuildContext
import 'package:flutter/rendering.dart'; // <-- needed for RenderRepaintBoundary

class WaveformPngExport {
  static Future<Uint8List> captureFromBoundary(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    final ctx = boundaryKey.currentContext;
    if (ctx == null) {
      throw StateError('captureFromBoundary: boundary context is null');
    }

    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('captureFromBoundary: renderObject is not a RenderRepaintBoundary');
    }

    final ui.Image image = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('captureFromBoundary: failed to encode PNG');
    }
    return byteData.buffer.asUint8List();
  }
}