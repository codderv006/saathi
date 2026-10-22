import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/workflow.dart';

/// Animated, brand-coloured vector mock of an app screen with a pulsing tap target.
/// Shown whenever a step has no real screenshot, so guidance is never blank.
class AppIllustration extends StatefulWidget {
  const AppIllustration({
    super.key,
    required this.visual,
    required this.appName,
    required this.color,
    required this.accent,
    this.maxHeight = 420,
  });

  final StepVisual visual;
  final String appName;
  final Color color;
  final Color accent;
  final double maxHeight;

  @override
  State<AppIllustration> createState() => _AppIllustrationState();
}

class _AppIllustrationState extends State<AppIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t;

  @override
  void initState() {
    super.initState();
    _t = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _t
        ..stop()
        ..value = 0.35;
    } else if (!_t.isAnimating) {
      _t.repeat();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.maxHeight.clamp(160.0, 900.0);
    return Center(
      child: Semantics(
        image: true,
        label: '${widget.appName} illustration',
        child: SizedBox(
          height: h,
          width: h * 0.52,
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, _) => CustomPaint(
              painter: _ScreenPainter(
                t: _t.value,
                kind: widget.visual.kind,
                focus: widget.visual.focus,
                appName: widget.appName,
                brand: widget.color,
                accent: widget.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenPainter extends CustomPainter {
  _ScreenPainter({
    required this.t,
    required this.kind,
    required this.focus,
    required this.appName,
    required this.brand,
    required this.accent,
  });

  final double t;
  final String kind;
  final String? focus;
  final String appName;
  final Color brand;
  final Color accent;

  static const _ink = Color(0xFF171719);
  static const _line = Color(0xFFE6E6EC);
  static const _soft = Color(0xFFF3F3F7);
  static const _muted = Color(0xFFB9B9C3);
  static const _green = Color(0xFF1FA85A);
  static const _red = Color(0xFFD9364F);
  static const _amber = Color(0xFFE8A317);

  late Canvas _c;
  late Rect _screen;
  Offset? _tap;

  double get _u => _screen.width / 100; // 1 unit = 1% of screen width

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    // Phone body with soft shadow.
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.12),
    );
    canvas.drawRRect(
      body.shift(const Offset(0, 6)),
      Paint()
        ..color = const Color(0x1A5B4BC4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawRRect(body, Paint()..color = _ink);
    _screen = Rect.fromLTWH(
      size.width * 0.035,
      size.width * 0.035,
      size.width * 0.93,
      size.height - size.width * 0.07,
    );
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(_screen, Radius.circular(size.width * 0.09)),
    );
    canvas.drawRect(_screen, Paint()..color = Colors.white);
    switch (kind) {
      case 'home_icon':
        _homeIcon();
      case 'play_store':
        _playStore();
      case 'keypad':
        _keypad();
      case 'otp':
        _otp();
      case 'permission':
        _permission();
      case 'search':
        _search();
      case 'list':
        _list();
      case 'button':
        _button();
      case 'map':
        _map(full: true);
      case 'ride_card':
        _rideCard();
      case 'qr':
        _qr();
      case 'bank':
        _bank();
      case 'menu':
        _menu();
      case 'receipt':
        _receipt();
      case 'shield':
        _shield();
      case 'chat':
        _chat();
      case 'keyboard':
        _keyboard();
      case 'profile':
        _profile();
      case 'contact':
        _contact();
      case 'status':
        _status();
      case 'community':
        _community();
      default:
        _header();
        _lines(_screen.top + 30 * _u, 5);
    }
    if (_tap != null) _tapRing(_tap!);
    canvas.restore();
    // Speaker notch.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, _screen.top + 3.2 * _u),
          width: 16 * _u,
          height: 3.2 * _u,
        ),
        Radius.circular(2 * _u),
      ),
      Paint()..color = _ink,
    );
  }

  // ------------------------------------------------------------ primitives

  Paint _p(Color c) => Paint()..color = c;

  void _r(Rect r, Color c, [double radius = 2.5]) => _c.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(radius * _u)),
    _p(c),
  );

  Rect _box(double l, double t, double w, double h) => Rect.fromLTWH(
    _screen.left + l * _u,
    _screen.top + t * _u,
    w * _u,
    h * _u,
  );

  void _text(
    String s,
    Offset at, {
    double size = 4.2,
    Color color = _ink,
    FontWeight weight = FontWeight.w600,
    bool center = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: size * _u,
          color: color,
          fontWeight: weight,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(_c, center ? at - Offset(tp.width / 2, tp.height / 2) : at);
  }

  void _lines(double top, int n, {double left = 8, double width = 84}) {
    for (var i = 0; i < n; i++) {
      final w = width * (i.isEven ? 1 : 0.7);
      _r(_box(left, (top - _screen.top) / _u + i * 9, w, 3.6), _soft, 1.8);
    }
  }

  void _header({String? title}) {
    final r = _box(0, 0, 100, 22);
    _c.drawRect(r, _p(brand));
    final fg = brand.computeLuminance() > 0.5 ? _ink : Colors.white;
    _text(
      title ?? appName,
      Offset(r.left + 7 * _u, r.top + 12 * _u),
      size: 5.4,
      color: fg,
    );
  }

  void _icon(Offset c, double r, Color color, {String? letter}) {
    _c.drawCircle(c, r, _p(color));
    if (letter != null) {
      _text(letter, c, size: r / _u, color: Colors.white, center: true);
    }
  }

  void _tapRing(Offset at) {
    for (final phase in [0.0, 0.5]) {
      final p = (t + phase) % 1.0;
      _c.drawCircle(
        at,
        (4 + p * 9) * _u,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9 * _u
          ..color = const Color(0xFF5B4BC4).withValues(alpha: (1 - p) * 0.9),
      );
    }
    _c.drawCircle(at, 3.4 * _u, _p(const Color(0xCC5B4BC4)));
    _c.drawCircle(at, 1.4 * _u, _p(Colors.white));
  }

  void _primaryButton(Rect r, String label, {Color? color}) {
    final c = color ?? brand;
    _r(r, c, 3.5);
    final fg = c.computeLuminance() > 0.5 ? _ink : Colors.white;
    _text(label, r.center, size: 4.4, color: fg, center: true);
  }

  // ------------------------------------------------------------ screens

  void _homeIcon() {
    _c.drawRect(_screen, _p(const Color(0xFFEDEBFA)));
    const cols = 4;
    for (var i = 0; i < 16; i++) {
      final col = i % cols, row = i ~/ cols;
      final center = Offset(
        _screen.left + (14 + col * 24) * _u,
        _screen.top + (34 + row * 26) * _u,
      );
      final isApp = i == 9;
      _r(
        Rect.fromCenter(center: center, width: 15 * _u, height: 15 * _u),
        isApp ? brand : Colors.white,
        4,
      );
      if (isApp) {
        final fg = brand.computeLuminance() > 0.5 ? _ink : Colors.white;
        _text(appName[0], center, size: 7, color: fg, center: true);
        _text(
          appName,
          center + Offset(0, 11 * _u),
          size: 3.4,
          center: true,
          weight: FontWeight.w500,
        );
        _tap = center;
      }
    }
  }

  void _playStore() {
    _r(_box(6, 8, 88, 10), _soft, 5);
    _text(
      appName,
      Offset(_screen.left + 12 * _u, _screen.top + 11 * _u),
      size: 4,
      weight: FontWeight.w500,
    );
    _r(_box(8, 26, 20, 20), brand, 5);
    final fg = brand.computeLuminance() > 0.5 ? _ink : Colors.white;
    _text(
      appName[0],
      _box(8, 26, 20, 20).center,
      size: 9,
      color: fg,
      center: true,
    );
    _text(
      appName,
      Offset(_screen.left + 33 * _u, _screen.top + 29 * _u),
      size: 5,
    );
    _r(_box(33, 37, 30, 3), _soft, 1.5);
    final install = _box(8, 52, 84, 11);
    _primaryButton(install, 'Install', color: _green);
    _tap = install.center;
    _lines(_screen.top + 72 * _u, 6);
  }

  void _keypad() {
    _header();
    final display = _box(10, 30, 80, 16);
    _r(display, _soft, 3);
    switch (focus) {
      case 'pin':
        for (var i = 0; i < 4; i++) {
          final filled = i < 1 + (t * 4).floor();
          _c.drawCircle(
            Offset(display.left + (16 + i * 16) * _u, display.center.dy),
            2.4 * _u,
            filled
                ? _p(_ink)
                : (Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 0.6 * _u
                    ..color = _muted),
          );
        }
        _text('UPI PIN', Offset(display.left, display.top - 6 * _u), size: 3.6);
      case 'amount':
        _text('₹ 250', display.center, size: 8, center: true);
      default:
        _text('+91  98••• •••••', display.center, size: 4.6, center: true);
    }
    for (var i = 0; i < 12; i++) {
      final col = i % 3, row = i ~/ 3;
      final key = _box(10 + col * 27.5, 56 + row * 16, 24, 13);
      _r(key, _soft, 3);
      const labels = [
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '',
        '0',
        '✓',
      ];
      if (labels[i] == '✓') {
        _r(key, brand, 3);
      }
      _text(
        labels[i],
        key.center,
        size: 5,
        center: true,
        color: labels[i] == '✓' && brand.computeLuminance() < 0.5
            ? Colors.white
            : _ink,
      );
      final pressed = (t * 6).floor() % 9;
      if (i == pressed && focus != 'amount') _tap = key.center;
    }
    if (focus == 'amount') {
      _tap = _box(10 + 2 * 27.5, 56 + 3 * 16, 24, 13).center;
    }
  }

  void _otp() {
    _header();
    final sms = _box(8, 28, 84, 16);
    _r(sms, const Color(0xFFE7F4EC), 3);
    _text(
      'SMS:  Your code is ••••',
      Offset(sms.left + 4 * _u, sms.top + 6 * _u),
      size: 3.8,
      weight: FontWeight.w500,
    );
    for (var i = 0; i < 4; i++) {
      final b = _box(13 + i * 19, 54, 14, 16);
      _c.drawRRect(
        RRect.fromRectAndRadius(b, Radius.circular(2.5 * _u)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7 * _u
          ..color = i <= (t * 4).floor() ? brand : _muted,
      );
      if (i < (t * 4).floor()) _text('•', b.center, size: 7, center: true);
    }
    _tap = _box(13, 54, 14, 16).center;
    _lines(_screen.top + 84 * _u, 4);
  }

  void _permission() {
    _header();
    _lines(_screen.top + 30 * _u, 6);
    _c.drawRect(_screen, _p(const Color(0x88000000)));
    final d = _box(8, 60, 84, 56);
    _r(d, const Color(0xFF2B2B30), 5);
    _text(
      'Allow $appName to use',
      Offset(d.left + 6 * _u, d.top + 7 * _u),
      size: 3.8,
      color: Colors.white,
    );
    _text(
      'your location?',
      Offset(d.left + 6 * _u, d.top + 13 * _u),
      size: 3.8,
      color: Colors.white,
    );
    const opts = ['While using the app', 'Only this time', "Don't allow"];
    for (var i = 0; i < 3; i++) {
      final o = Offset(d.center.dx, d.top + (27 + i * 10) * _u);
      _text(
        opts[i],
        o,
        size: 3.8,
        color: const Color(0xFF8AB4F8),
        center: true,
      );
      if (i == 0) _tap = o;
    }
  }

  void _search() {
    _header();
    final bar = _box(6, 27, 88, 11);
    _r(bar, Colors.white, 4);
    _c.drawRRect(
      RRect.fromRectAndRadius(bar, Radius.circular(4 * _u)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7 * _u
        ..color = brand,
    );
    _text(
      'Where to?',
      Offset(bar.left + 9 * _u, bar.top + 3.6 * _u),
      size: 4,
      color: _muted,
      weight: FontWeight.w500,
    );
    _c.drawCircle(
      Offset(bar.left + 4.5 * _u, bar.center.dy),
      1.6 * _u,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6 * _u
        ..color = _ink,
    );
    _tap = bar.center;
    if (focus == 'map') {
      _map(top: 44);
    } else {
      for (var i = 0; i < 5; i++) {
        _icon(
          Offset(_screen.left + 10 * _u, _screen.top + (50 + i * 13) * _u),
          2.6 * _u,
          _soft,
        );
        _r(_box(16, 48 + i * 13, 60, 3.4), _soft, 1.7);
        _r(_box(16, 53 + i * 13, 40, 2.6), _soft, 1.3);
      }
    }
  }

  void _list() {
    _header();
    for (var i = 0; i < 5; i++) {
      final row = _box(5, 28 + i * 18, 90, 15);
      final hl = (focus == 'first' && i == 0) || (focus == 'second' && i == 1);
      _r(row, hl ? brand.withValues(alpha: 0.10) : Colors.white, 3);
      _icon(
        Offset(row.left + 7 * _u, row.center.dy),
        4 * _u,
        i == 0 ? accent : _soft,
      );
      _r(
        Rect.fromLTWH(
          row.left + 14 * _u,
          row.top + 3.5 * _u,
          38 * _u,
          3.4 * _u,
        ),
        _line,
        1.7,
      );
      _r(
        Rect.fromLTWH(
          row.left + 14 * _u,
          row.top + 8.5 * _u,
          24 * _u,
          2.6 * _u,
        ),
        _soft,
        1.3,
      );
      _text(
        '₹${[130, 227, 344, 347, 512][i]}',
        Offset(row.right - 16 * _u, row.top + 4 * _u),
        size: 3.8,
      );
      if (hl) _tap = row.center;
      if (focus == 'price' && i == 1) {
        _tap = Offset(row.right - 10 * _u, row.top + 6 * _u);
      }
    }
    if (focus == 'bottom') {
      final bar = _box(5, 124, 90, 10);
      _r(bar, _soft, 3);
      _text('Cash  ›', Offset(bar.left + 4 * _u, bar.top + 3 * _u), size: 3.8);
      _tap = Offset(bar.left + 12 * _u, bar.center.dy);
    }
    _tap ??= _box(5, 28, 90, 15).center;
  }

  void _button() {
    _header();
    _lines(_screen.top + 32 * _u, 7);
    final b = _box(8, _screen.height / _u - 22, 84, 12);
    final red = focus == 'red';
    _primaryButton(b, red ? 'End' : 'Continue', color: red ? _red : null);
    _tap = b.center;
  }

  void _map({bool full = false, double top = 22}) {
    if (full) _header();
    final m = Rect.fromLTRB(
      _screen.left,
      _screen.top + top * _u,
      _screen.right,
      _screen.bottom,
    );
    _c.drawRect(m, _p(const Color(0xFFF1F0EA)));
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 3 * _u;
    for (var i = 0; i < 6; i++) {
      final y = m.top + (12 + i * 22) * _u;
      _c.drawLine(Offset(m.left, y), Offset(m.right, y + 6 * _u), road);
    }
    for (var i = 0; i < 4; i++) {
      final x = m.left + (12 + i * 26) * _u;
      _c.drawLine(Offset(x, m.top), Offset(x + 4 * _u, m.bottom), road);
    }
    final a = Offset(m.left + 22 * _u, m.top + 30 * _u);
    final b = Offset(m.left + 72 * _u, m.top + 90 * _u);
    final route = Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx + 40 * _u, a.dy, b.dx - 40 * _u, b.dy, b.dx, b.dy);
    _c.drawPath(
      route,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * _u
        ..color = _ink,
    );
    _c.drawCircle(a, 2.6 * _u, _p(_green));
    // Pin at destination.
    _c.drawCircle(b - Offset(0, 4 * _u), 3.2 * _u, _p(_red));
    _c.drawCircle(b - Offset(0, 4 * _u), 1.2 * _u, _p(Colors.white));
    // Car moving along the route.
    final metric = route.computeMetrics().first;
    final pos = metric.getTangentForOffset(metric.length * t)!.position;
    _r(
      Rect.fromCenter(center: pos, width: 6 * _u, height: 4 * _u),
      accent,
      1.2,
    );
    _tap = switch (focus) {
      'car' => pos,
      'pin' => b - Offset(0, 4 * _u),
      'route' => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2),
      _ => null,
    };
  }

  void _rideCard() {
    _map(top: 0);
    _tap = null;
    final card = Rect.fromLTWH(
      _screen.left,
      _screen.top + _screen.height * 0.5,
      _screen.width,
      _screen.height * 0.5,
    );
    _c.drawRRect(
      RRect.fromRectAndCorners(
        card,
        topLeft: Radius.circular(6 * _u),
        topRight: Radius.circular(6 * _u),
      ),
      _p(Colors.white),
    );
    double y(double v) => card.top + v * _u;
    _text('3 mins away', Offset(card.left + 7 * _u, y(6)), size: 4.6);
    _icon(Offset(card.right - 13 * _u, y(20)), 6 * _u, _soft);
    final plate = Rect.fromLTWH(card.left + 7 * _u, y(15), 40 * _u, 8 * _u);
    _r(plate, const Color(0xFFFFF3CC), 1.8);
    _text('MH 15 AB 1234', plate.center, size: 3.6, center: true);
    _text(
      'Driver  ★ 4.9',
      Offset(card.left + 7 * _u, y(27)),
      size: 3.6,
      weight: FontWeight.w500,
    );
    final otp = Rect.fromLTWH(card.left + 54 * _u, y(5), 30 * _u, 7 * _u);
    _r(otp, brand.withValues(alpha: 0.12), 1.8);
    _text('OTP  ••••', otp.center, size: 3.6, center: true);
    final call = Offset(card.left + 12 * _u, y(42));
    _icon(call, 5 * _u, _soft);
    _text('☎', call, size: 4.6, center: true);
    final chat = Rect.fromLTWH(card.left + 20 * _u, y(37), 52 * _u, 10 * _u);
    _r(chat, _soft, 5);
    _text(
      'Message driver…',
      Offset(chat.left + 4 * _u, chat.top + 3 * _u),
      size: 3.4,
      color: _muted,
      weight: FontWeight.w500,
    );
    final share = Offset(card.right - 12 * _u, y(42));
    _icon(share, 5 * _u, _soft);
    _text('↗', share, size: 4.6, center: true);
    final cancel = Offset(card.center.dx, y(57));
    _text('Cancel ride', cancel, size: 3.8, color: _red, center: true);
    final fare = Offset(card.left + 22 * _u, y(57));
    if (focus == 'fare') {
      _text('₹248', fare, size: 4, center: true);
    }
    _tap = switch (focus) {
      'plate' => plate.center,
      'otp' => otp.center,
      'call' => call,
      'chat' => chat.center,
      'share' => share,
      'cancel' => cancel,
      'eta' => Offset(card.left + 20 * _u, y(8)),
      'fare' => fare,
      _ => null,
    };
  }

  void _qr() {
    if (focus == 'mine') {
      _header();
      final card = _box(14, 32, 72, 72);
      _r(card, Colors.white, 4);
      _qrPattern(card.deflate(8 * _u));
      _text(
        'your@upi',
        Offset(card.center.dx, card.bottom + 6 * _u),
        size: 3.8,
        center: true,
      );
      _tap = card.center;
      return;
    }
    _c.drawRect(_screen, _p(const Color(0xFF1B1B20)));
    final frame = _box(18, 40, 64, 64);
    _qrPattern(frame.deflate(6 * _u), color: Colors.white);
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * _u
      ..color = Colors.white;
    for (final (dx, dy) in [(0, 0), (1, 0), (0, 1), (1, 1)]) {
      final x = dx == 0 ? frame.left : frame.right;
      final yy = dy == 0 ? frame.top : frame.bottom;
      final sx = dx == 0 ? 1 : -1, sy = dy == 0 ? 1 : -1;
      _c.drawLine(Offset(x, yy), Offset(x + sx * 9 * _u, yy), corner);
      _c.drawLine(Offset(x, yy), Offset(x, yy + sy * 9 * _u), corner);
    }
    final scanY =
        frame.top + frame.height * (0.5 + 0.45 * math.sin(t * 2 * math.pi));
    _c.drawLine(
      Offset(frame.left + 3 * _u, scanY),
      Offset(frame.right - 3 * _u, scanY),
      Paint()
        ..color = accent
        ..strokeWidth = 0.9 * _u,
    );
    _text(
      'Scan any QR',
      Offset(_screen.center.dx, _screen.top + 22 * _u),
      size: 4.4,
      color: Colors.white,
      center: true,
    );
    _tap = frame.center;
  }

  void _qrPattern(Rect r, {Color color = _ink}) {
    final cell = r.width / 9;
    final rnd = math.Random(7);
    for (var i = 0; i < 9; i++) {
      for (var j = 0; j < 9; j++) {
        final finder = (i < 3 && j < 3) || (i > 5 && j < 3) || (i < 3 && j > 5);
        if (finder || rnd.nextBool()) {
          _c.drawRect(
            Rect.fromLTWH(
              r.left + i * cell,
              r.top + j * cell,
              cell * 0.9,
              cell * 0.9,
            ),
            _p(color),
          );
        }
      }
    }
  }

  void _bank() {
    _header();
    if (focus == 'card') {
      final card = _box(10, 32, 80, 48);
      _c.drawRRect(
        RRect.fromRectAndRadius(card, Radius.circular(4 * _u)),
        Paint()
          ..shader = LinearGradient(colors: [brand, accent]).createShader(card),
      );
      _text(
        '•••• •••• •••• 4821',
        Offset(card.left + 6 * _u, card.top + 22 * _u),
        size: 4.6,
        color: Colors.white,
      );
      _text(
        'MM/YY   CVV •••',
        Offset(card.left + 6 * _u, card.top + 34 * _u),
        size: 3.6,
        color: Colors.white,
      );
      _tap = Offset(card.left + 30 * _u, card.top + 24 * _u);
      _lines(_screen.top + 92 * _u, 4);
      return;
    }
    if (focus == 'refund') {
      final c = Offset(_screen.center.dx, _screen.top + 62 * _u);
      _icon(c, 20 * _u, const Color(0xFFE7F4EC));
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * _u
        ..strokeCap = StrokeCap.round
        ..color = _green;
      _c.drawArc(
        Rect.fromCircle(center: c, radius: 11 * _u),
        -math.pi / 2 + t * 2 * math.pi,
        math.pi * 1.4,
        false,
        arc,
      );
      _text('₹ → 🏦', Offset(c.dx, c.dy + 30 * _u), size: 5, center: true);
      _tap = c;
      return;
    }
    const banks = [
      Color(0xFF0B4EA2),
      Color(0xFFE76F00),
      Color(0xFF7A1E8C),
      Color(0xFF00897B),
      Color(0xFFC62828),
    ];
    for (var i = 0; i < 5; i++) {
      final row = _box(6, 28 + i * 17, 88, 14);
      _r(row, i == 0 ? brand.withValues(alpha: 0.08) : Colors.white, 3);
      _r(
        Rect.fromLTWH(row.left + 3 * _u, row.top + 2.5 * _u, 9 * _u, 9 * _u),
        banks[i],
        2,
      );
      _r(
        Rect.fromLTWH(row.left + 16 * _u, row.top + 5 * _u, 40 * _u, 3.6 * _u),
        _line,
        1.8,
      );
    }
    _tap = _box(6, 28, 88, 14).center;
  }

  void _menu() {
    _header();
    _lines(_screen.top + 30 * _u, 8);
    final dots = Offset(_screen.right - 8 * _u, _screen.top + 13 * _u);
    for (var i = -1; i <= 1; i++) {
      _c.drawCircle(
        dots + Offset(0, i * 2 * _u),
        0.8 * _u,
        _p(brand.computeLuminance() > 0.5 ? _ink : Colors.white),
      );
    }
    final menu = _box(46, 18, 50, 50);
    _c.drawRRect(
      RRect.fromRectAndRadius(
        menu.shift(Offset(0, 1 * _u)),
        Radius.circular(3 * _u),
      ),
      Paint()
        ..color = const Color(0x22000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    _r(menu, Colors.white, 3);
    final items = switch (focus) {
      'bank' => ['Profile', 'Bank account', 'Settings', 'Help'],
      'card' => ['Profile', 'Payment methods', 'Settings', 'Help'],
      'balance' => ['Check balance', 'History', 'Settings', 'Help'],
      'history' => ['History', 'Offers', 'Settings', 'Help'],
      'help' => ['Details', 'Get help', 'Share', 'Repeat'],
      'edit' => ['View contact', 'Edit', 'Search', 'Mute'],
      'block' => ['Search', 'Mute', 'More', 'Block'],
      'settings' => ['New group', 'Linked devices', 'Starred', 'Settings'],
      _ => ['Option', 'Option', 'Option', 'Option'],
    };
    final pick = switch (focus) {
      'bank' || 'card' || 'help' || 'edit' => 1,
      'block' || 'settings' => 3,
      _ => 0,
    };
    for (var i = 0; i < items.length; i++) {
      final row = Rect.fromLTWH(
        menu.left,
        menu.top + (3 + i * 11.5) * _u,
        menu.width,
        10 * _u,
      );
      if (i == pick) _r(row.deflate(1 * _u), brand.withValues(alpha: 0.12), 2);
      _text(
        items[i],
        Offset(row.left + 4 * _u, row.top + 3 * _u),
        size: 3.6,
        weight: FontWeight.w500,
      );
      if (i == pick) _tap = row.center;
    }
  }

  void _receipt() {
    _header();
    final c = Offset(_screen.center.dx, _screen.top + 58 * _u);
    final (Color col, String label) = switch (focus) {
      'pending' => (_amber, 'Pending'),
      'amount' => (brand, '₹ 248'),
      _ => (_green, 'Payment successful'),
    };
    _c.drawCircle(
      c,
      (16 + 2 * math.sin(t * 2 * math.pi)) * _u,
      _p(col.withValues(alpha: 0.15)),
    );
    _c.drawCircle(c, 11 * _u, _p(col));
    if (focus == 'pending') {
      final hand = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.2 * _u
        ..strokeCap = StrokeCap.round;
      _c.drawLine(c, c + Offset(0, -6 * _u), hand);
      _c.drawLine(c, c + Offset(4 * _u, 2 * _u), hand);
    } else {
      final tick = Path()
        ..moveTo(c.dx - 5 * _u, c.dy)
        ..lineTo(c.dx - 1 * _u, c.dy + 4 * _u)
        ..lineTo(c.dx + 6 * _u, c.dy - 4 * _u);
      final m = tick.computeMetrics().first;
      _c.drawPath(
        m.extractPath(0, m.length * (0.3 + 0.7 * t)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * _u
          ..strokeCap = StrokeCap.round
          ..color = Colors.white,
      );
    }
    _text(label, Offset(c.dx, c.dy + 22 * _u), size: 5, center: true);
    if (focus != 'amount') {
      _text(
        '₹ 250',
        Offset(c.dx, c.dy + 30 * _u),
        size: 4,
        center: true,
        weight: FontWeight.w500,
      );
    }
    _lines(_screen.top + 104 * _u, 4);
    _tap = c;
  }

  void _shield() {
    _c.drawRect(_screen, _p(const Color(0xFFF4F1FF)));
    final c = Offset(_screen.center.dx, _screen.top + 64 * _u);
    final glow = 22 + 3 * math.sin(t * 2 * math.pi);
    _c.drawCircle(c, glow * _u, _p(const Color(0x225B4BC4)));
    final s = 14 * _u;
    final shield = Path()
      ..moveTo(c.dx, c.dy - s)
      ..lineTo(c.dx + s * 0.85, c.dy - s * 0.6)
      ..lineTo(c.dx + s * 0.7, c.dy + s * 0.4)
      ..quadraticBezierTo(
        c.dx + s * 0.3,
        c.dy + s * 0.95,
        c.dx,
        c.dy + s * 1.05,
      )
      ..quadraticBezierTo(
        c.dx - s * 0.3,
        c.dy + s * 0.95,
        c.dx - s * 0.7,
        c.dy + s * 0.4,
      )
      ..lineTo(c.dx - s * 0.85, c.dy - s * 0.6)
      ..close();
    _c.drawPath(shield, _p(const Color(0xFF5B4BC4)));
    final glyph = switch (focus) {
      'plate' => '🚗',
      'sos' => 'SOS',
      'people' => '👥',
      _ => '🔒',
    };
    _text(
      glyph,
      c,
      size: focus == 'sos' ? 4.4 : 7,
      color: Colors.white,
      center: true,
    );
    _text(
      appName,
      Offset(c.dx, c.dy + 30 * _u),
      size: 4,
      center: true,
      color: const Color(0xFF5B4BC4),
    );
  }

  void _chat() {
    if (focus == 'fab') {
      _header(title: appName);
      for (var i = 0; i < 6; i++) {
        _icon(
          Offset(_screen.left + 10 * _u, _screen.top + (32 + i * 15) * _u),
          4.5 * _u,
          i == 0 ? accent : _soft,
        );
        _r(_box(18, 29 + i * 15, 46, 3.4), _line, 1.7);
        _r(_box(18, 34 + i * 15, 30, 2.6), _soft, 1.3);
      }
      final fab = Offset(_screen.right - 12 * _u, _screen.bottom - 14 * _u);
      _r(
        Rect.fromCenter(center: fab, width: 13 * _u, height: 13 * _u),
        brand,
        4,
      );
      _text('+', fab, size: 6, color: Colors.white, center: true);
      _tap = fab;
      return;
    }
    // Header with name, video and call icons.
    final header = _box(0, 0, 100, 22);
    _c.drawRect(header, _p(accent));
    _icon(Offset(header.left + 10 * _u, header.top + 13 * _u), 4 * _u, _soft);
    _text(
      'Asha',
      Offset(header.left + 17 * _u, header.top + 11 * _u),
      size: 4.4,
      color: Colors.white,
    );
    final video = Offset(header.right - 22 * _u, header.top + 13 * _u);
    _text('▶', video, size: 4.4, color: Colors.white, center: true);
    _text(
      '☎',
      Offset(header.right - 11 * _u, header.top + 13 * _u),
      size: 4.4,
      color: Colors.white,
      center: true,
    );
    _c.drawRect(
      Rect.fromLTRB(_screen.left, header.bottom, _screen.right, _screen.bottom),
      _p(const Color(0xFFEFE7DE)),
    );
    // Bubbles.
    _r(_box(6, 30, 54, 10), Colors.white, 3);
    _r(_box(40, 44, 54, 10), const Color(0xFFD9FDD3), 3);
    if (focus == 'link') {
      final link = _box(6, 58, 70, 14);
      _r(link, Colors.white, 3);
      _text(
        'chat.whatsapp.com/…',
        Offset(link.left + 4 * _u, link.top + 5 * _u),
        size: 3.6,
        color: const Color(0xFF027EB5),
        weight: FontWeight.w500,
      );
      _tap = link.center;
    } else {
      _r(_box(6, 58, 44, 10), Colors.white, 3);
    }
    // Input bar.
    final bar = Rect.fromLTWH(
      _screen.left + 3 * _u,
      _screen.bottom - 16 * _u,
      78 * _u,
      12 * _u,
    );
    _r(bar, Colors.white, 6);
    _text(
      focus == 'input' ? 'Type a message|' : 'Message',
      Offset(bar.left + 6 * _u, bar.top + 4 * _u),
      size: 3.8,
      color: _muted,
      weight: FontWeight.w500,
    );
    final attach = Offset(bar.right - 18 * _u, bar.center.dy);
    _text('📎', attach, size: 4, center: true);
    final cam = Offset(bar.right - 8 * _u, bar.center.dy);
    _text('📷', cam, size: 4, center: true);
    final send = Offset(_screen.right - 9 * _u, bar.center.dy);
    _c.drawCircle(send, 6 * _u, _p(brand));
    _text(
      focus == 'send' ? '➤' : '🎤',
      send,
      size: 4.6,
      color: Colors.white,
      center: true,
    );
    _tap ??= switch (focus) {
      'input' => bar.center,
      'attach' => attach,
      'send' || 'mic' => send,
      'video' => video,
      _ => null,
    };
  }

  void _keyboard() {
    _c.drawRect(_screen, _p(const Color(0xFFEFE7DE)));
    final bar = Rect.fromLTWH(
      _screen.left + 3 * _u,
      _screen.top + 66 * _u,
      94 * _u,
      12 * _u,
    );
    _r(bar, Colors.white, 6);
    _text('नमस्कार|', Offset(bar.left + 6 * _u, bar.top + 4 * _u), size: 4);
    final kb = Rect.fromLTRB(
      _screen.left,
      _screen.top + 82 * _u,
      _screen.right,
      _screen.bottom,
    );
    _c.drawRect(kb, _p(const Color(0xFFE3E5EA)));
    final gear = Offset(kb.left + 9 * _u, kb.top + 6 * _u);
    _text('⚙', gear, size: 4.6, center: true);
    for (var row = 0; row < 3; row++) {
      for (var k = 0; k < 9; k++) {
        _r(
          Rect.fromLTWH(
            kb.left + (2 + k * 10.7) * _u,
            kb.top + (13 + row * 13) * _u,
            9 * _u,
            10.5 * _u,
          ),
          Colors.white,
          1.6,
        );
      }
    }
    final globe = Rect.fromLTWH(
      kb.left + 2 * _u,
      kb.top + 53 * _u,
      12 * _u,
      10.5 * _u,
    );
    _r(globe, const Color(0xFFCFD3DA), 1.6);
    _text('🌐', globe.center, size: 4.2, center: true);
    final space = Rect.fromLTWH(
      kb.left + 16 * _u,
      kb.top + 53 * _u,
      60 * _u,
      10.5 * _u,
    );
    _r(space, Colors.white, 1.6);
    _text(
      'English • मराठी',
      space.center,
      size: 3.2,
      color: _muted,
      center: true,
    );
    _tap = switch (focus) {
      'gear' => gear,
      'globe' => globe.center,
      _ => bar.center,
    };
  }

  void _profile() {
    _header(title: 'Profile');
    final c = Offset(_screen.center.dx, _screen.top + 50 * _u);
    _icon(c, 17 * _u, _soft);
    _text('👤', c, size: 12, center: true);
    final badge = c + Offset(12 * _u, 12 * _u);
    _icon(badge, 5 * _u, brand);
    _text('📷', badge, size: 3.6, center: true);
    final name = Rect.fromLTWH(
      _screen.left + 12 * _u,
      _screen.top + 76 * _u,
      76 * _u,
      10 * _u,
    );
    _r(name, _soft, 3);
    _text('Your name', Offset(name.left + 4 * _u, name.top + 3 * _u), size: 4);
    _lines(_screen.top + 96 * _u, 4);
    _tap = focus == 'name' ? name.center : badge;
  }

  void _contact() {
    _header(title: 'Edit contact');
    final save = Offset(_screen.right - 12 * _u, _screen.top + 12 * _u);
    _text(
      'Save',
      save,
      size: 4.2,
      color: brand.computeLuminance() > 0.5 ? _ink : Colors.white,
      center: true,
    );
    final fields = ['Name', 'Phone'];
    for (var i = 0; i < 2; i++) {
      final f = _box(8, 32 + i * 18, 84, 12);
      _c.drawRRect(
        RRect.fromRectAndRadius(f, Radius.circular(2.5 * _u)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6 * _u
          ..color = i == 0 ? brand : _muted,
      );
      _text(
        i == 0 ? 'Asha Tai|' : '+91 98••• •••••',
        Offset(f.left + 4 * _u, f.top + 4 * _u),
        size: 4,
      );
      _text(
        fields[i],
        Offset(f.left + 3 * _u, f.top - 3.5 * _u),
        size: 3,
        color: _muted,
      );
    }
    _tap = save;
  }

  void _status() {
    _header(title: 'Updates');
    for (var i = 0; i < 4; i++) {
      final c = Offset(
        _screen.left + (14 + i * 24) * _u,
        _screen.top + 36 * _u,
      );
      _c.drawCircle(
        c,
        8 * _u,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 * _u
          ..color = i == 0 ? _muted : brand,
      );
      _icon(c, 6.5 * _u, _soft);
    }
    _text(
      'My status',
      Offset(_screen.left + 6 * _u, _screen.top + 47 * _u),
      size: 3.2,
      weight: FontWeight.w500,
    );
    _lines(_screen.top + 60 * _u, 5);
    final pencil = Offset(_screen.right - 12 * _u, _screen.bottom - 34 * _u);
    _r(
      Rect.fromCenter(center: pencil, width: 10 * _u, height: 10 * _u),
      _soft,
      3,
    );
    _text('✎', pencil, size: 4.4, center: true);
    final cam = Offset(_screen.right - 12 * _u, _screen.bottom - 18 * _u);
    _r(Rect.fromCenter(center: cam, width: 13 * _u, height: 13 * _u), brand, 4);
    _text('📷', cam, size: 4.6, center: true);
    final tabs = Rect.fromLTWH(
      _screen.left,
      _screen.bottom - 8 * _u,
      _screen.width,
      8 * _u,
    );
    _c.drawRect(tabs, _p(_soft));
    final updates = Offset(_screen.left + 37 * _u, tabs.center.dy);
    _text(
      'Chats   Updates   Calls',
      Offset(_screen.center.dx, tabs.center.dy),
      size: 3,
      center: true,
      weight: FontWeight.w500,
    );
    _tap = switch (focus) {
      'add' => cam,
      'send' => cam,
      _ => updates,
    };
  }

  void _community() {
    _header(title: 'Communities');
    final hub = Offset(_screen.center.dx, _screen.top + 64 * _u);
    final spokes = 6;
    for (var i = 0; i < spokes; i++) {
      final a = i / spokes * 2 * math.pi + t * 0.6;
      final p = hub + Offset(math.cos(a), math.sin(a)) * 28 * _u;
      _c.drawLine(
        hub,
        p,
        Paint()
          ..color = _line
          ..strokeWidth = 0.6 * _u,
      );
      _icon(p, 6 * _u, i.isEven ? accent.withValues(alpha: 0.8) : brand);
    }
    _icon(hub, 10 * _u, brand);
    _text('📢', hub, size: 6, center: true);
    if (focus == 'join') {
      final b = _box(14, _screen.height / _u - 20, 72, 11);
      _primaryButton(b, 'Join group');
      _tap = b.center;
    } else {
      _tap = hub;
    }
  }

  @override
  bool shouldRepaint(_ScreenPainter old) =>
      old.t != t || old.kind != kind || old.focus != focus;
}
