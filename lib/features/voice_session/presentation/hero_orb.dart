import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/voice_session_service.dart';

/// The big tappable voice button: a glowing core with pulsing rings and slowly
/// orbiting arcs. Its motion follows the call (calm when idle, rippling while
/// Saathi speaks, spinning while connecting). Static with reduced motion.
class HeroOrb extends StatefulWidget {
  const HeroOrb({
    super.key,
    required this.status,
    this.size = 240,
    this.onTap,
    this.semanticLabel,
  });

  final VoiceStatus status;
  final double size;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<HeroOrb> createState() => _HeroOrbState();
}

class _HeroOrbState extends State<HeroOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _t;

  @override
  void initState() {
    super.initState();
    _t = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _t
        ..stop()
        ..value = 0.2;
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
    final phase = widget.status.phase;
    final icon = switch (phase) {
      VoicePhase.muted => Icons.mic_off_rounded,
      VoicePhase.speaking => Icons.graphic_eq_rounded,
      VoicePhase.failed => Icons.priority_high_rounded,
      _ => Icons.mic_rounded,
    };
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, _) => CustomPaint(
              painter: _OrbPainter(t: _t.value, phase: phase),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    icon,
                    key: ValueKey(icon),
                    size: widget.size * 0.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.t, required this.phase});

  final double t;
  final VoicePhase phase;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final core = r * 0.42;
    final (Color a, Color b) = switch (phase) {
      VoicePhase.failed => (AppColors.roseStrong, const Color(0xFFF07A90)),
      VoicePhase.muted => (const Color(0xFF8A8A96), const Color(0xFFB5B5C0)),
      VoicePhase.listening => (AppColors.mintStrong, const Color(0xFF5FD1A0)),
      _ => (AppColors.lavenderStrong, const Color(0xFF8E7CFF)),
    };

    // Ripples: speed and count follow the call state.
    final speed = switch (phase) {
      VoicePhase.speaking => 3.0,
      VoicePhase.listening => 2.0,
      VoicePhase.connecting || VoicePhase.requestingPermission => 1.5,
      _ => 1.0,
    };
    for (var i = 0; i < 3; i++) {
      final p = (t * speed + i / 3) % 1.0;
      canvas.drawCircle(
        c,
        core + (r - core) * p,
        Paint()..color = a.withValues(alpha: 0.16 * (1 - p)),
      );
    }

    // Orbiting arcs.
    final arcSpeed = phase == VoicePhase.connecting ? 4.0 : 1.0;
    for (final (radius, sweep, dir, width) in [
      (core * 1.42, math.pi * 0.55, 1.0, 3.0),
      (core * 1.7, math.pi * 0.35, -1.0, 2.0),
      (core * 1.95, math.pi * 0.2, 1.0, 1.5),
    ]) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: radius),
        dir * t * 2 * math.pi * arcSpeed,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width
          ..color = a.withValues(alpha: 0.55),
      );
    }

    // Glow + gradient core that breathes.
    final breathe = 1 + 0.03 * math.sin(t * 2 * math.pi * speed);
    canvas.drawCircle(
      c,
      core * 1.15 * breathe,
      Paint()
        ..color = a.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    final coreRect = Rect.fromCircle(center: c, radius: core * breathe);
    canvas.drawCircle(
      c,
      core * breathe,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [b, a],
        ).createShader(coreRect),
    );
    // Soft highlight.
    canvas.drawCircle(
      c + Offset(-core * 0.3, -core * 0.35),
      core * 0.35,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t || old.phase != phase;
}
