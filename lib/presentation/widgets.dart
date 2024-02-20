import 'package:flutter/material.dart';

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE3E3E3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    int dotPadding = 20;
    var dx = 0.0, dy = 0.0;
    final dotsPath = Path();
    for (var j = 0; j < size.height / dotPadding; j++) {
      for (var i = 0; i < size.width / dotPadding; i++) {
        paint
          ..style = PaintingStyle.fill
          ..color = const Color(0xFF0098EE);
        Rect oval = Rect.fromCircle(
            center: Offset(dx + dotPadding / 2, dy + dotPadding / 2),
            radius: 1);
        dotsPath.addOval(oval);
        dx += dotPadding;
      }
      dy += dotPadding;
      dx = 0;
    }
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF0098EE);
    canvas.drawPath(dotsPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
