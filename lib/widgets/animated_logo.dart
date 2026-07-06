import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

enum AnimatedLogoSize { xl, lg, md, sm }

class AnimatedLogo extends StatefulWidget {
  final AnimatedLogoSize size;
  final bool horizontal;
  final bool showText;
  final bool showTagline;
  final Color? textColor;
  final Color? textAccentColor;

  const AnimatedLogo({
    super.key,
    this.size = AnimatedLogoSize.md,
    this.horizontal = false,
    this.showText = true,
    this.showTagline = false,
    this.textColor,
    this.textAccentColor,
  });

  double get _scale {
    switch (size) {
      case AnimatedLogoSize.xl:
        return 1.0;
      case AnimatedLogoSize.lg:
        return 0.75;
      case AnimatedLogoSize.md:
        return 0.5;
      case AnimatedLogoSize.sm:
        return 0.25;
    }
  }

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _scanController;
  late AnimationController _dotsController;
  late AnimationController _reticleController;
  late AnimationController _cornersController;
  late AnimationController _textController;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _reticleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _cornersController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _ringController.dispose();
    _scanController.dispose();
    _dotsController.dispose();
    _reticleController.dispose();
    _cornersController.dispose();
    _textController.dispose();
    super.dispose();
  }

  double get s => widget._scale;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _buildIconArea(),
      if (widget.showText) _buildTextArea(),
    ];

    return widget.horizontal
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              children[0],
              SizedBox(width: 14 * s),
              if (children.length > 1) children[1],
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: children.length > 1
                ? [children[0], SizedBox(height: 20 * s), children[1]]
                : [children[0]],
          );
  }

  Widget _buildIconArea() {
    return SizedBox(
      width: 160 * s,
      height: 160 * s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ring 1
          AnimatedBuilder(
            animation: _ringController,
            builder: (_, __) {
              final t = _ringController.value;
              final scale = 0.6 + (t * 0.4);
              final opacity = (1.0 - t) * 0.6;
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 160 * s,
                    height: 160 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF43A047),
                        width: 1.5 * s,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Ring 2 (offset delay)
          AnimatedBuilder(
            animation: _ringController,
            builder: (_, __) {
              final raw = (_ringController.value + 0.5) % 1.0;
              final scale = 0.6 + (raw * 0.4);
              final opacity = (1.0 - raw) * 0.6;
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 130 * s,
                    height: 130 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF43A047),
                        width: 1.5 * s,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Icon bg
          Container(
            width: 110 * s,
            height: 110 * s,
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.all(Radius.circular(32 * s)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Scan line
                AnimatedBuilder(
                  animation: _scanController,
                  builder: (_, __) {
                    final t = _scanController.value;
                    final top = lerpDouble(8 * s, 102 * s, t)!;
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: top,
                      child: Opacity(
                        opacity: t < 0.1 ? t / 0.1 : (t > 0.9 ? (1.0 - t) / 0.1 : 1.0),
                        child: Container(
                          height: 2 * s,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Color(0xFFA5D6A7), Color(0xFF69F0AE), Color(0xFFA5D6A7), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Corners
                AnimatedBuilder(
                  animation: _cornersController,
                  builder: (_, __) {
                    final t = _cornersController.value;
                    final opacity = _pulseOpacity(t, 0.0, 0.4, 0.6, 0.85);
                    return Opacity(
                      opacity: opacity,
                      child: Stack(
                        children: [
                          _corner(8 * s, 8 * s, Alignment.topLeft),
                          _corner(8 * s, 8 * s, Alignment.topRight),
                          _corner(8 * s, 8 * s, Alignment.bottomLeft),
                          _corner(8 * s, 8 * s, Alignment.bottomRight),
                        ],
                      ),
                    );
                  },
                ),
                // Leaf SVG
                Center(
                  child: SizedBox(
                    width: 68 * s,
                    height: 80 * s,
                    child: CustomPaint(
                      painter: _LeafPainter(s),
                    ),
                  ),
                ),
                // Roya dots
                AnimatedBuilder(
                  animation: _dotsController,
                  builder: (_, __) {
                    final t = _dotsController.value;
                    return Stack(
                      children: [
                        _royaDot(22 * s, 44 * s, 5 * s, _dotOpacity(t, 0.0), const Color(0xFFFF6D00)),
                        _royaDot(28 * s, 54 * s, 3.5 * s, _dotOpacity(t, 0.15), const Color(0xFFE64A19)),
                        _royaDot(46 * s, 36 * s, 5 * s, _dotOpacity(t, 0.3), const Color(0xFFFF6D00)),
                      ],
                    );
                  },
                ),
                // Reticle
                AnimatedBuilder(
                  animation: _reticleController,
                  builder: (_, __) {
                    final t = _reticleController.value;
                    final opacity = _pulseOpacity(t, 0.0, 0.45, 0.65, 0.85);
                    final scale = _pulseScale(t, 0.0, 0.45, 0.65);
                    return Positioned(
                      left: 22 * s - 9 * s,
                      top: 44 * s - 9 * s,
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: CustomPaint(
                            size: Size(18 * s, 18 * s),
                            painter: _ReticlePainter(s),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea() {
    return FadeTransition(
      opacity: _textController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _textController,
          curve: Curves.easeOutCubic,
        )),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "CoffeLife" text
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 52 * s,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2 * s,
                  height: 1,
                  color: widget.textColor ?? const Color(0xFF1B5E20),
                ),
                children: [
                  const TextSpan(text: 'Coffe'),
                  TextSpan(
                    text: 'Life',
                    style: TextStyle(color: widget.textAccentColor ?? const Color(0xFF43A047)),
                  ),
                ],
              ),
            ),
            // Accent bar
            AnimatedBuilder(
              animation: _textController,
              builder: (_, __) {
                final t = _textController.value;
                final delay = (t - 0.3).clamp(0.0, 1.0);
                return Container(
                  width: 48 * s * delay,
                  height: 3 * s,
                  margin: EdgeInsets.symmetric(vertical: 6 * s),
                  decoration: BoxDecoration(
                    color: widget.textAccentColor ?? const Color(0xFF43A047),
                    borderRadius: BorderRadius.all(Radius.circular(2 * s)),
                  ),
                );
              },
            ),
            // Tagline
            if (widget.showTagline)
              Text(
                'Cuida tu cultivo, hoja a hoja',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12 * s,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.5 * s,
                  fontStyle: FontStyle.italic,
                  color: widget.textAccentColor?.withValues(alpha: 0.5) ?? const Color(0xFF81C784),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _corner(double x, double y, Alignment align) {
    return Positioned(
      left: align == Alignment.topLeft || align == Alignment.bottomLeft ? x : null,
      right: align == Alignment.topRight || align == Alignment.bottomRight ? x : null,
      top: align == Alignment.topLeft || align == Alignment.topRight ? y : null,
      bottom: align == Alignment.bottomLeft || align == Alignment.bottomRight ? y : null,
      child: CustomPaint(
        size: Size(14 * s, 14 * s),
        painter: _CornerPainter(align, s),
      ),
    );
  }

  Widget _royaDot(double left, double top, double radius, double opacity, Color color) {
    return Positioned(
      left: left - radius,
      top: top - radius,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }

  double _pulseOpacity(double t, double start, double fadeIn, double hold, double fadeOut) {
    if (t < start) return 0;
    if (t < fadeIn) return (t - start) / (fadeIn - start);
    if (t < hold) return 1.0;
    if (t < fadeOut) return 1.0;
    if (t < 1.0) {
      final tail = (t - fadeOut) / (1.0 - fadeOut);
      return 1.0 - tail * 0.7;
    }
    return 0.3;
  }

  double _pulseScale(double t, double start, double fadeIn, double hold) {
    if (t < start) return 0.5;
    if (t < fadeIn) {
      final p = (t - start) / (fadeIn - start);
      return 0.5 + p * 0.5;
    }
    if (t < hold) return 1.0;
    if (t < 1.0) return 1.0;
    return 1.0;
  }

  double _dotOpacity(double t, double delay) {
    final shifted = (t - delay) % 1.0;
    if (shifted < 0.35) return 0;
    if (shifted < 0.55) return (shifted - 0.35) / 0.2;
    if (shifted < 0.80) return 1.0;
    if (shifted < 1.0) return 1.0 - (shifted - 0.80) / 0.2 * 0.7;
    return 0.3;
  }
}

// ── Leaf painter ──
class _LeafPainter extends CustomPainter {
  final double s;
  _LeafPainter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    // Outer leaf
    final outerPaint = Paint()..color = const Color(0xFF2E7D32);
    final outerPath = Path()
      ..moveTo(w * 0.5, 4 * s)
      ..cubicTo(20 * s, 4 * s, 8 * s, 18 * s, 8 * s, 36 * s)
      ..cubicTo(8 * s, 54 * s, 20 * s, 72 * s, 34 * s, 76 * s)
      ..cubicTo(48 * s, 72 * s, 60 * s, 54 * s, 60 * s, 36 * s)
      ..cubicTo(60 * s, 18 * s, 48 * s, 4 * s, w * 0.5, 4 * s)
      ..close();
    canvas.drawPath(outerPath, outerPaint);

    // Inner leaf
    final innerPaint = Paint()..color = const Color(0xFF388E3C);
    final innerPath = Path()
      ..moveTo(w * 0.5, 12 * s)
      ..cubicTo(22 * s, 12 * s, 14 * s, 22 * s, 14 * s, 36 * s)
      ..cubicTo(14 * s, 50 * s, 22 * s, 66 * s, 34 * s, 70 * s)
      ..cubicTo(46 * s, 66 * s, 54 * s, 50 * s, 54 * s, 36 * s)
      ..cubicTo(54 * s, 22 * s, 46 * s, 12 * s, w * 0.5, 12 * s)
      ..close();
    canvas.drawPath(innerPath, innerPaint);

    final veinPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 1.8 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Central vein
    canvas.drawLine(
      Offset(w * 0.5, 8 * s),
      Offset(w * 0.5, 74 * s),
      veinPaint,
    );

    // Side veins
    final sideVeinPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 1.2 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final veins = [
      [Offset(w * 0.5, 28 * s), Offset(18 * s, 40 * s)],
      [Offset(w * 0.5, 42 * s), Offset(16 * s, 52 * s)],
      [Offset(w * 0.5, 56 * s), Offset(20 * s, 63 * s)],
      [Offset(w * 0.5, 28 * s), Offset(50 * s, 40 * s)],
      [Offset(w * 0.5, 42 * s), Offset(52 * s, 52 * s)],
      [Offset(w * 0.5, 56 * s), Offset(48 * s, 63 * s)],
    ];

    for (final v in veins) {
      canvas.drawLine(v[0], v[1], sideVeinPaint);
    }
  }

  @override
  bool shouldRepaint(_LeafPainter old) => old.s != s;
}

// ── Reticle painter ──
class _ReticlePainter extends CustomPainter {
  final double s;
  _ReticlePainter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = 9 * s;

    final paint = Paint()
      ..color = const Color(0xFFFFEA00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * s;

    canvas.drawCircle(Offset(cx, cy), r, paint);

    final linePaint = Paint()
      ..color = const Color(0xFFFFEA00)
      ..strokeWidth = 1.2 * s
      ..strokeCap = StrokeCap.round;

    // Crosshair lines
    canvas.drawLine(Offset(cx, cy - 12 * s), Offset(cx, cy - 8 * s), linePaint);
    canvas.drawLine(Offset(cx, cy + 8 * s), Offset(cx, cy + 12 * s), linePaint);
    canvas.drawLine(Offset(cx - 12 * s, cy), Offset(cx - 8 * s, cy), linePaint);
    canvas.drawLine(Offset(cx + 8 * s, cy), Offset(cx + 12 * s, cy), linePaint);
  }

  @override
  bool shouldRepaint(_ReticlePainter old) => old.s != s;
}

// ── Corner painter ──
class _CornerPainter extends CustomPainter {
  final Alignment align;
  final double s;
  _CornerPainter(this.align, this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF69F0AE)
      ..strokeWidth = 2 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (align == Alignment.topLeft) {
      canvas.drawLine(Offset(0, size.height), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
    } else if (align == Alignment.topRight) {
      canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
    } else if (align == Alignment.bottomLeft) {
      canvas.drawLine(const Offset(0, 0), Offset(0, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
    } else if (align == Alignment.bottomRight) {
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width, size.height), Offset(0, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.align != align || old.s != s;
}
