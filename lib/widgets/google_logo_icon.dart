import 'package:flutter/material.dart';

/// Paints the official Google 'G' logo using four coloured arcs.
/// Drop-in replacement for flutter_svg — zero extra dependency.
class GoogleLogoIcon extends StatelessWidget {
  final double size;
  const GoogleLogoIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final paint = Paint()..style = PaintingStyle.fill;

    // Blue (right arc + horizontal bar)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, s, s),
      -0.52,
      1.04,
      true,
      paint,
    );
    // White cut-out inner circle
    paint.color = Colors.white;
    canvas.drawCircle(Offset(s / 2, s / 2), s * 0.325, paint);

    // White horizontal bar (right half)
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(s * 0.5, s * 0.42, s * 0.5, s * 0.16), paint);
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(s * 0.5, s * 0.42, s * 0.5, s * 0.16), Paint()..color = Colors.white);

    // Re-draw using path for accuracy
    _drawGoogleG(canvas, size);
  }

  void _drawGoogleG(Canvas canvas, Size size) {
    final double s = size.width;
    final Offset c = Offset(s / 2, s / 2);
    final double r = s / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // Red - top left quarter
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(c.dx, c.dy)
      ..arcTo(Rect.fromCircle(center: c, radius: r), -2.36, 1.57, false)
      ..close();
    canvas.drawPath(redPath, paint);

    // Blue - top right + right
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(c.dx, c.dy)
      ..arcTo(Rect.fromCircle(center: c, radius: r), -0.79, 1.57, false)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Yellow - bottom left
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(c.dx, c.dy)
      ..arcTo(Rect.fromCircle(center: c, radius: r), 2.36, 0.79, false)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Green - bottom right
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(c.dx, c.dy)
      ..arcTo(Rect.fromCircle(center: c, radius: r), 3.14, 1.18, false)
      ..close();
    canvas.drawPath(greenPath, paint);

    // White inner circle (creates the C shape)
    paint.color = Colors.white;
    canvas.drawCircle(c, r * 0.65, paint);

    // Blue horizontal bar on right (the G cross bar)
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - r * 0.16, r, r * 0.32),
      paint,
    );

    // White inner circle again to clean up bar
    paint.color = Colors.white;
    canvas.drawCircle(c, r * 0.58, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
