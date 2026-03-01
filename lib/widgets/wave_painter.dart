import 'package:flutter/material.dart';
import 'dart:math' as math;

class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color waveColor;
  final Color secondWaveColor;

  WavePainter({
    required this.animation,
    required this.waveColor,
    required this.secondWaveColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(canvas, size, waveColor, 1.0, 10.0, 5.0);
    _drawWave(canvas, size, secondWaveColor, -0.5, 15.0, 7.5);
  }

  void _drawWave(Canvas canvas, Size size, Color color, double phaseShift, double amplitude1, double amplitude2) {
    final paint = Paint()..color = color;
    final path = Path();
    final y = size.height * 0.8;
    path.moveTo(0, y);

    for (int i = 0; i < size.width; i++) {
      path.lineTo(
        i.toDouble(),
        y + math.sin((animation.value * 360 + phaseShift * i) * math.pi / 180) * amplitude1 +
            math.sin((animation.value * 720 + phaseShift * i) * math.pi / 180) * amplitude2
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}
