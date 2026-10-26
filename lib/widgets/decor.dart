import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Row of punched holes — the "perforated divider" between ink and paper bands.
class Perforation extends StatelessWidget {
  const Perforation({super.key, this.background = DB.paper, this.holeColor = DB.ink});

  final Color background;
  final Color holeColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      width: double.infinity,
      child: CustomPaint(painter: _PerfPainter(background, holeColor)),
    );
  }
}

class _PerfPainter extends CustomPainter {
  _PerfPainter(this.bg, this.hole);
  final Color bg;
  final Color hole;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    final p = Paint()..color = hole;
    const step = 22.0;
    final count = (size.width / step).ceil();
    final startX = (size.width - (count - 1) * step) / 2;
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(Offset(startX + i * step, size.height / 2), 4, p);
    }
  }

  @override
  bool shouldRepaint(_PerfPainter old) => old.bg != bg || old.hole != hole;
}

/// Clips a card with scalloped (ticket-stub) notches on the left & right edges
/// at [notchY], plus an optional scalloped top/bottom edge.
class TicketClipper extends CustomClipper<Path> {
  TicketClipper({this.notchY, this.notchRadius = 10, this.scallopEdges = false});

  /// Distance from top of the side notches. Null = vertical centre.
  final double? notchY;
  final double notchRadius;
  final bool scallopEdges;

  @override
  Path getClip(Size size) {
    final y = notchY ?? size.height / 2;
    var path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(DB.radius)));
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, y), radius: notchRadius))
      ..addOval(Rect.fromCircle(center: Offset(size.width, y), radius: notchRadius));
    if (scallopEdges) {
      const step = 14.0;
      for (double x = step / 2; x < size.width; x += step) {
        holes.addOval(Rect.fromCircle(center: Offset(x, 0), radius: 4.5));
        holes.addOval(Rect.fromCircle(center: Offset(x, size.height), radius: 4.5));
      }
    }
    path = Path.combine(PathOperation.difference, path, holes);
    return path;
  }

  @override
  bool shouldReclip(TicketClipper old) =>
      old.notchY != notchY || old.notchRadius != notchRadius || old.scallopEdges != scallopEdges;
}

/// Horizontal dashed rule — used as the tear line on ticket cards.
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, this.color = DB.line, this.dash = 6, this.gap = 4, this.thickness = 1.2});

  final Color color;
  final double dash;
  final double gap;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: thickness,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter(color, dash, gap, thickness)),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.dash, this.gap, this.thickness);
  final Color color;
  final double dash, gap, thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = thickness;
    for (double x = 0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(math.min(x + dash, size.width), size.height / 2), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// Decorative barcode strip (same rhythm as the website's .barcode gradient).
class Barcode extends StatelessWidget {
  const Barcode({super.key, this.height = 30, this.color = DB.ink, this.seed = 7});

  final double height;
  final Color color;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _BarcodePainter(color, seed)),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  _BarcodePainter(this.color, this.seed);
  final Color color;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final p = Paint()..color = color.withValues(alpha: 0.85);
    double x = 0;
    while (x < size.width) {
      final w = (rnd.nextInt(3) + 1).toDouble();
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), p);
      x += w + rnd.nextInt(3) + 2;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => old.color != color || old.seed != seed;
}

/// Rotated, dashed circular stamp — "20% OFF", "VERIFIED TODAY", etc.
class Stamp extends StatelessWidget {
  const Stamp({
    super.key,
    required this.top,
    this.bottom = 'OFF',
    this.color = DB.coral,
    this.size = 58,
    this.angle = -10,
    this.fill = DB.paper,
  });

  final String top;
  final String bottom;
  final Color color;
  final double size;
  final double angle;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * math.pi / 180,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DashedCirclePainter(color, fill),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(child: Text(top, style: DB.display(size * 0.26, color: color))),
                  if (bottom.isNotEmpty)
                    FittedBox(child: Text(bottom, style: DB.mono(size * 0.14, color: DB.ink))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter(this.color, this.fill);
  final Color color;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1.5;
    canvas.drawCircle(c, r, Paint()..color = fill);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const segs = 28;
    for (var i = 0; i < segs; i++) {
      final start = (i / segs) * 2 * math.pi;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, (math.pi / segs) * 1.1, false, p);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color || old.fill != fill;
}

/// Small mono eyebrow label used above section titles.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = DB.coral});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: DB.mono(11, color: color));
}
