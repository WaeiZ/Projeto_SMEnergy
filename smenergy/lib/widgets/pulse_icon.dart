import 'package:flutter/material.dart';

class PulseIcon extends StatelessWidget {
  final double size;
  final double strokeWidth;

  const PulseIcon({super.key, this.size = 56, this.strokeWidth = 3});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PulseIconPainter(strokeWidth: strokeWidth),
      ),
    );
  }
}

class _PulseIconPainter extends CustomPainter {
  final double strokeWidth;

  _PulseIconPainter({required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.36;
    final innerRadius = size.width * 0.26;
    final centerRadius = size.width * 0.16;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFF1D7EF8), Color(0xFF6A5CFF)],
      ).createShader(
        Rect.fromCircle(center: center, radius: outerRadius + 6),
      );

    // Left arcs
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      2.1,
      2.1,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      2.1,
      2.1,
      false,
      paint,
    );

    // Right arcs
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      -1.0,
      2.1,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      -1.0,
      2.1,
      false,
      paint,
    );

    // Center ring
    canvas.drawCircle(center, centerRadius, paint);

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - outerRadius),
      Offset(center.dx, center.dy + outerRadius),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
