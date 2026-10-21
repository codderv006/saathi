import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/voice_session_service.dart';

/// Calm status visual: soft orb that breathes while listening, ripples while Saathi
/// speaks and pulses while connecting. Static when the system asks for reduced motion.
/// Meaning is always also given by the icon and the status text next to it.
class VoiceOrb extends StatefulWidget {
  const VoiceOrb({super.key, required this.status, this.size = 168});

  final VoiceStatus status;
  final double size;

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  bool get _animated => switch (widget.status.phase) {
    VoicePhase.connecting ||
    VoicePhase.listening ||
    VoicePhase.speaking ||
    VoicePhase.requestingPermission => true,
    _ => false,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(VoiceOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_animated && !reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.status.phase;
    final (Color fill, IconData icon) = switch (phase) {
      VoicePhase.listening => (AppColors.mint, Icons.mic_rounded),
      VoicePhase.speaking => (AppColors.lavender, Icons.graphic_eq_rounded),
      VoicePhase.muted => (AppColors.disabledSurface, Icons.mic_off_rounded),
      VoicePhase.failed => (AppColors.rose, Icons.priority_high_rounded),
      VoicePhase.disconnected => (
        AppColors.peach,
        Icons.portable_wifi_off_rounded,
      ),
      VoicePhase.ended => (AppColors.surfaceMuted, Icons.call_end_rounded),
      _ => (AppColors.softBlue, Icons.mic_none_rounded),
    };
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _OrbPainter(
              t: _controller.value,
              phase: phase,
              fill: fill,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Icon(
                  icon,
                  key: ValueKey(icon),
                  size: widget.size * 0.24,
                  color: AppColors.textPrimary,
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
  _OrbPainter({required this.t, required this.phase, required this.fill});

  final double t;
  final VoicePhase phase;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final base = size.width * 0.30;
    final wave = math.sin(t * 2 * math.pi);

    switch (phase) {
      case VoicePhase.speaking:
        // Two expanding ripples.
        for (final offset in [0.0, 0.5]) {
          final p = (t + offset) % 1.0;
          canvas.drawCircle(
            c,
            base + p * size.width * 0.20,
            Paint()..color = fill.withValues(alpha: (1 - p) * 0.9),
          );
        }
      case VoicePhase.listening:
        canvas.drawCircle(
          c,
          base * (1.18 + 0.06 * wave),
          Paint()..color = fill.withValues(alpha: 0.55),
        );
      case VoicePhase.connecting || VoicePhase.requestingPermission:
        canvas.drawCircle(
          c,
          base * 1.25,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = AppColors.border,
        );
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: base * 1.25),
          t * 2 * math.pi,
          math.pi / 2,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round
            ..color = AppColors.lavenderStrong,
        );
      default:
        break;
    }
    canvas.drawCircle(c, base, Paint()..color = fill);
    canvas.drawCircle(
      c,
      base,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.textPrimary.withValues(alpha: 0.06),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.t != t || old.phase != phase || old.fill != fill;
}
