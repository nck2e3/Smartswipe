
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RingPainter extends CustomPainter {
  const RingPainter({
    required this.percentage,
    this.startColor,
    this.endColor,
    this.width,
  }) : assert(percentage >= 0 && percentage <= 100,
  "Percentage must be in the range 0-100!");

  final double percentage;
  final Color? startColor;
  final Color? endColor;
  final double? width;

  double get progress => percentage / 100;

  @override
  void paint(Canvas canvas, Size size) {
    var angle = pi / 180 * 230;
    canvas.rotateAroundCenter(size, angle);
    canvas.drawRing(
      size,
      1,
      startColor: Colors.black12,
      endColor: Colors.black12,
      width: width,
    );
    canvas.drawRing(
      size,
      progress,
      startColor: startColor,
      endColor: endColor,
      width: width,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

extension on Canvas {
  rotateAroundCenter(Size size, double angleInRadians) {
    final double r = sqrt(size.width * size.width + size.height * size.height) / 2;
    final alpha = atan(size.height / size.width);
    final beta = alpha + angleInRadians;
    final shiftY = r * sin(beta);
    final shiftX = r * cos(beta);
    final translateX = size.width / 2 - shiftX;
    final translateY = size.height / 2 - shiftY;
    translate(translateX, translateY);
    rotate(angleInRadians);
  }

  drawRing(
      Size size,
      double value, {
        Color? startColor,
        Color? endColor,
        double? width,
      }) {
    final rect = Rect.fromLTWH(-15, 0.0, size.width, size.height);
    final gradient = SweepGradient(
      startAngle: 3 * pi / 2,
      endAngle: 7 * pi / 2,
      tileMode: TileMode.repeated,
      colors: [
        startColor ?? Colors.white,
        endColor ?? Colors.blueGrey,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = width ?? 24;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - ((width ?? 24) / 2);
    const startAngle = - pi / 2;
    final sweepAngle = 2 * pi * value * 0.723;

    drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }
}