import 'dart:math' as math;
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════
//  Red Ocean — Promo Banner Widget
//  Usage: RedOceanBanner() أو RedOceanBanner.compact()
// ══════════════════════════════════════════════════════

class RedOceanBanner extends StatefulWidget {
  final String? imagePath; // مسار صورة الحوت في assets
  final VoidCallback? onTap;
  final bool compact; // نسخة مصغّرة للموبايل

  const RedOceanBanner({
    super.key,
    this.imagePath,
    this.onTap,
    this.compact = false,
  });

  /// نسخة مضغوطة للشاشات الصغيرة
  const RedOceanBanner.compact({
    super.key,
    this.imagePath,
    this.onTap,
  }) : compact = true;

  @override
  State<RedOceanBanner> createState() => _RedOceanBannerState();
}

class _RedOceanBannerState extends State<RedOceanBanner>
    with TickerProviderStateMixin {
  late AnimationController _whaleController;
  late AnimationController _badge1Controller;
  late AnimationController _badge2Controller;
  late AnimationController _badge3Controller;
  late AnimationController _bubbleController;

  late Animation<double> _whaleAnim;
  late Animation<double> _badge1Anim;
  late Animation<double> _badge2Anim;
  late Animation<double> _badge3Anim;

  @override
  void initState() {
    super.initState();

    _whaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _badge1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _badge2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _badge3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _whaleAnim = Tween<double>(begin: 0, end: -14).animate(
      CurvedAnimation(parent: _whaleController, curve: Curves.easeInOut),
    );
    _badge1Anim = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(parent: _badge1Controller, curve: Curves.easeInOut),
    );
    _badge2Anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _badge2Controller, curve: Curves.easeInOut),
    );
    _badge3Anim = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _badge3Controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _whaleController.dispose();
    _badge1Controller.dispose();
    _badge2Controller.dispose();
    _badge3Controller.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  static const _red = Color(0xFFE8000E);
  static const _darkBg = Color(0xFF070707);
  static const _darkPanel = Color(0xFF0F0F0F);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: widget.compact ? _buildCompact() : _buildFull(),
    );
  }

  // ── الشكل الكامل (landscape / tablet) ──
  Widget _buildFull() {
    return Container(
      decoration: BoxDecoration(
        color: _darkBg,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: AspectRatio(
        aspectRatio: 1400 / 467,
        child: Stack(
          children: [
            // Grid lines
            _GridLines(),

            Row(
              children: [
                // ── Panel LEFT: نص ──
                Expanded(
                  flex: 42,
                  child: _buildTextPanel(large: true),
                ),

                // ── Panel RIGHT: الحوت ──
                Expanded(
                  flex: 58,
                  child: _buildWhalePanel(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact() {
    return SizedBox(
      height: 200,
      child: _buildWhalePanel(),
    );
  }

  // ────────────────────────────────
  //  PANEL: النص
  // ────────────────────────────────
  Widget _buildTextPanel({required bool large}) {
    return Container(
      color: _darkPanel,
      child: Stack(
        children: [
          // الخط الأحمر الجانبي
          Positioned(
            right: 0,
            top: 40,
            bottom: 40,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _red,
                    _red,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.25, 0.75, 1.0],
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: large ? 48 : 24,
              vertical: large ? 40 : 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tag
                Text(
                  'FLASH SALE · يومياً',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: large ? 10 : 9,
                    color: _red,
                    letterSpacing: 3,
                  ),
                ),
                SizedBox(height: large ? 16 : 10),

                // Headline
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'الأسعار\n'),
                      TextSpan(
                        text: 'تغرق\n',
                        style: const TextStyle(color: _red),
                      ),
                      TextSpan(
                        text: 'وتوفيرك يطفو',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: large ? 28 : 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: large ? 44 : 28,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: large ? 10 : 6),

                // Sub
                Text(
                  'آلاف الخصومات من أكبر المتاجر الإلكترونية\nفي مكان واحد — تتجدد كل ساعة',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: large ? 11 : 10,
                    color: Colors.white.withOpacity(0.3),
                    height: 1.7,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: large ? 28 : 16),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _StatChip(num: '+200', label: 'متجر', large: large),
                    _vDivider(),
                    _StatChip(num: '70%', label: 'أقصى خصم', large: large),
                    _vDivider(),
                    _StatChip(num: '24h', label: 'يومياً', large: large),
                  ],
                ),
                SizedBox(height: large ? 28 : 16),

                // CTA Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (large)
                      TextButton(
                        onPressed: widget.onTap,
                        child: Text(
                          'تعرّف أكثر',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontFamily: 'monospace',
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: widget.onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: large ? 26 : 18,
                          vertical: large ? 14 : 10,
                        ),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: Text(
                        'اكتشف العروض ←',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: large ? 13 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────
  //  PANEL: الحوت
  // ────────────────────────────────
  Widget _buildWhalePanel() {
    return Stack(
      children: [
        // Depth rings
        ..._depthRings(),

        // Top glow
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_red.withOpacity(0.10), Colors.transparent],
              ),
            ),
          ),
        ),

        // Bubbles
        _BubblesWidget(animation: _bubbleController),

        // THE WHALE
        Center(
          child: AnimatedBuilder(
            animation: _whaleAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _whaleAnim.value),
              child: child,
            ),
            child: _buildWhaleImage(),
          ),
        ),

        // Deal tags
        Positioned(
          top: 40,
          right: 95,
          child: AnimatedBuilder(
            animation: _badge1Anim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _badge1Anim.value),
              child: child,
            ),
            child: _DealTag(percent: '70%', store: 'Noon'),
          ),
        ),
        Positioned(
          top: 125,
          right: 300,
          child: AnimatedBuilder(
            animation: _badge1Anim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _badge1Anim.value),
              child: child,
            ),
            child: _DealTag(percent: '24hr', store: 'Noon'),
          ),
        ),
        Positioned(
          bottom: 80,
          right: 16,
          child: AnimatedBuilder(
            animation: _badge2Anim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _badge2Anim.value),
              child: child,
            ),
            child: _DealTag(percent: '50%', store: 'Amazon'),
          ),
        ),
        Positioned(
          bottom: 30,
          right: 120,
          child: AnimatedBuilder(
            animation: _badge3Anim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _badge3Anim.value),
              child: child,
            ),
            child: _DealTag(percent: '40%', store: 'Shein'),
          ),
        ),
      ],
    );
  }

  Widget _buildWhaleImage() {
    // إذا كان مسار الصورة موجود استخدمه، وإلا ارسم الحوت بـ CustomPaint
    if (widget.imagePath != null) {
      return Image.asset(
        widget.imagePath!,
        width: 320,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }
    // Fallback: رسم الحوت بـ SVG-like polygons
    return SizedBox(
      width: 300,
      height: 180,
      child: CustomPaint(painter: _WhalePainter()),
    );
  }

  List<Widget> _depthRings() {
    return [0.9, 0.7, 0.5].asMap().entries.map((e) {
      final opacity = 0.06 + e.key * 0.03;
      return Center(
        child: FractionallySizedBox(
          widthFactor: e.value,
          heightFactor: e.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _red.withOpacity(opacity),
                width: 1,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.white.withOpacity(0.08),
      );
}

// ─────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String num;
  final String label;
  final bool large;
  const _StatChip(
      {required this.num, required this.label, required this.large});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(
            text: num,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: large ? 26 : 20,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: large ? 10 : 9,
            color: Colors.white.withOpacity(0.3),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _DealTag extends StatelessWidget {
  final String percent;
  final String store;
  const _DealTag({required this.percent, required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE8000E).withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            percent,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 22,
              color: Color(0xFFE8000E),
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            store.toUpperCase(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: Colors.white.withOpacity(0.45),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridLines extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      size: Size.infinite,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────
//  Bubble animation widget
// ─────────────────────────────────────────
class _BubblesWidget extends StatelessWidget {
  final Animation<double> animation;
  const _BubblesWidget({required this.animation});

  static final _rng = math.Random(42);
  static final _bubbles = List.generate(
      16,
      (_) => (
            x: 0.3 + _rng.nextDouble() * 0.6,
            size: 3.0 + _rng.nextDouble() * 10,
            speed: 0.4 + _rng.nextDouble() * 0.6,
            offset: _rng.nextDouble(),
          ));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return CustomPaint(
          painter: _BubblePainter(animation.value, _bubbles),
          size: Size.infinite,
        );
      },
    );
  }
}

class _BubblePainter extends CustomPainter {
  final double t;
  final List<({double x, double size, double speed, double offset})> bubbles;

  _BubblePainter(this.t, this.bubbles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final b in bubbles) {
      final progress = ((t * b.speed + b.offset) % 1.0);
      final y = size.height * (1.0 - progress * 1.5);
      if (y < -b.size) continue;
      final x = size.width * b.x;
      final opacity = (1.0 - progress) * 0.5;
      paint.color = const Color(0xFFE8000E).withOpacity(opacity * 0.5);
      canvas.drawCircle(Offset(x, y), b.size / 2, paint);
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.t != t;
}

// ─────────────────────────────────────────
//  Whale Painter (fallback بدون صورة)
// ─────────────────────────────────────────
class _WhalePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 400;

    Path p(List<List<double>> pts) {
      final path = Path();
      path.moveTo(pts[0][0] * s, pts[0][1] * s);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i][0] * s, pts[i][1] * s);
      }
      path.close();
      return path;
    }

    void draw(List<List<double>> pts, Color c) =>
        canvas.drawPath(p(pts), Paint()..color = c);

    draw([
      [20, 160],
      [120, 80],
      [160, 130],
      [100, 180]
    ], const Color(0xFFE8000E));
    draw([
      [120, 80],
      [200, 40],
      [240, 100],
      [160, 130]
    ], const Color(0xFFC8000C));
    draw([
      [200, 40],
      [300, 60],
      [280, 120],
      [240, 100]
    ], const Color(0xFFE8000E));
    draw([
      [280, 120],
      [300, 60],
      [360, 20],
      [350, 90]
    ], const Color(0xFFFF2222));
    draw([
      [280, 120],
      [350, 90],
      [370, 140],
      [310, 160]
    ], const Color(0xFFC8000C));
    draw([
      [100, 180],
      [160, 130],
      [180, 190],
      [120, 210]
    ], const Color(0xFFB80008));
    draw([
      [160, 130],
      [240, 100],
      [220, 170],
      [180, 190]
    ], const Color(0xFFE8000E));
    draw([
      [240, 100],
      [280, 120],
      [260, 180],
      [220, 170]
    ], const Color(0xFFC8000C));
    draw([
      [310, 160],
      [370, 140],
      [360, 190],
      [320, 200]
    ], const Color(0xFFE8000E));
    draw([
      [310, 160],
      [320, 200],
      [270, 210],
      [260, 180]
    ], const Color(0xFFB80008));
    draw([
      [20, 160],
      [60, 190],
      [80, 210],
      [100, 180]
    ], const Color(0xFF9B0000));
    draw([
      [260, 180],
      [270, 210],
      [310, 220],
      [320, 200]
    ], const Color(0xFFFF2222));
    draw([
      [320, 200],
      [310, 220],
      [350, 215],
      [360, 190]
    ], const Color(0xFFE8000E));
    draw([
      [180, 190],
      [220, 170],
      [210, 215],
      [185, 215]
    ], const Color(0xFF9B0000));

    // Eye
    canvas.drawCircle(
      Offset(100 * s, 118 * s),
      5 * s,
      Paint()..color = const Color(0xFF6a0000),
    );
    canvas.drawCircle(
      Offset(101 * s, 117 * s),
      2 * s,
      Paint()..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
