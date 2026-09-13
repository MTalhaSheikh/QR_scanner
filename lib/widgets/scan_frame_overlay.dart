import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Draws the dimmed backdrop with a cut-out square scan window, corner
/// brackets, and an animated scanning laser line — the classic
/// "professional scanner app" look.
///
/// This widget is designed to be placed inside an `Expanded` (or any other
/// bounded box) between the header and the bottom controls. It only ever
/// paints within the box Flutter's layout system actually gives it, so by
/// construction it can never overlap the header or the controls, on any
/// screen size — there's no manual measuring or hard-coded offsets to get
/// out of sync.
class ScanFrameOverlay extends StatefulWidget {
  const ScanFrameOverlay({super.key});

  @override
  State<ScanFrameOverlay> createState() => _ScanFrameOverlayState();
}

class _ScanFrameOverlayState extends State<ScanFrameOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _OverlayPainter(linePosition: _controller.value),
              );
            },
          );
        },
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double linePosition;

  _OverlayPainter({required this.linePosition});

  @override
  void paint(Canvas canvas, Size size) {
    // The window is sized relative to whatever box we were given — never
    // relative to the full screen — so it always fits comfortably inside
    // it with margin to spare.
    final windowSize = [
      size.width * 0.78,
      size.height * 0.82,
      280.0,
    ].reduce((a, b) => a < b ? a : b).clamp(140.0, double.infinity);

    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(center: center, width: windowSize, height: windowSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(28));

    // Dim background with a clear cut-out window.
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(rrect);
    final overlayPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(overlayPath, Paint()..color = Colors.black.withOpacity(0.55));

    // Corner brackets
    final bracketPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const bracketLen = 28.0;
    final r = rect;

    void corner(Offset a, Offset b, Offset c) {
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy);
      canvas.drawPath(path, bracketPaint);
    }

    // top-left
    corner(Offset(r.left, r.top + bracketLen), Offset(r.left, r.top + 14),
        Offset(r.left + bracketLen, r.top));
    // top-right
    corner(Offset(r.right - bracketLen, r.top), Offset(r.right - 14, r.top),
        Offset(r.right, r.top + bracketLen));
    // bottom-left
    corner(Offset(r.left, r.bottom - bracketLen), Offset(r.left, r.bottom - 14),
        Offset(r.left + bracketLen, r.bottom));
    // bottom-right
    corner(Offset(r.right - bracketLen, r.bottom), Offset(r.right - 14, r.bottom),
        Offset(r.right, r.bottom - bracketLen));

    // Rounded window border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );

    // Animated scanning laser line
    final laserY = r.top + 10 + (r.height - 20) * linePosition;
    final laserRect = Rect.fromLTWH(r.left + 6, laserY - 1, r.width - 12, 2);
    final laserPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.accent.withOpacity(0.0),
          AppColors.accent,
          AppColors.accent.withOpacity(0.0),
        ],
      ).createShader(laserRect);
    canvas.drawRect(laserRect.inflate(1), laserPaint);
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) =>
      oldDelegate.linePosition != linePosition;
}
