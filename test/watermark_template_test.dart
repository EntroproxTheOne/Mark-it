import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mark_it/src/models/watermark_data.dart';
import 'package:mark_it/src/models/watermark_template.dart';

void main() {
  test(
    'template match includes style fields that distinguish similar templates',
    () {
      final data = WatermarkData(
        frameType: FrameType.whiteFrame,
        watermarkPosition: WatermarkPosition.belowImage,
        textColor: Colors.black,
        frameColor: Colors.white,
        borderRadius: 0,
        fontFamily: 'Inter',
      );

      final center = WatermarkTemplates.all.firstWhere(
        (t) => t.id == 'white_below_center',
      );
      final rounded = WatermarkTemplates.all.firstWhere(
        (t) => t.id == 'white_rounded',
      );

      expect(center.matches(data), isTrue);
      expect(rounded.matches(data), isFalse);
    },
  );
}
