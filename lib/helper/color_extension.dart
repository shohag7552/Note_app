import 'package:flutter/material.dart';

extension ColorExtension on String {
  toColor() {
    var hexStringColor = this;
    final buffer = StringBuffer();

    if (hexStringColor.length == 6 || hexStringColor.length == 9) {
      buffer.write('ff');
      buffer.write(hexStringColor.replaceFirst("#", ""));
      return Color(int.parse(buffer.toString(), radix: 16));
    }
  }

  convertString() {
    var color = this;
    print(color);
    return color.replaceAll('Color(0x', '#').replaceAll(")", '');
  }
}