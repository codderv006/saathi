import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/workflow.dart';

/// Maps a normalized annotation rect onto the displayed image. The image is always
/// shown at exactly [displayed] size (aspect preserved, no cropping), so fractions of
/// the original image map 1:1 onto it.
Rect annotationRect(NormalizedRect r, Size displayed) => Rect.fromLTWH(
  r.left * displayed.width,
  r.top * displayed.height,
  r.width * displayed.width,
  r.height * displayed.height,
);

/// Largest size with the image's aspect ratio that fits in [box] (BoxFit.contain).
Size fittedImageSize(Size image, Size box) =>
    applyBoxFit(BoxFit.contain, image, box).destination;

/// Shows a step's screenshot with highlight annotations drawn as a separate layer
/// (the source image is never modified). Missing assets show a labelled placeholder.
class ScreenshotGuide extends StatefulWidget {
  const ScreenshotGuide({
    super.key,
    required this.screenshot,
    required this.language,
    this.maxHeight = 440,
    this.pulse = 0,
    this.imageOverride,
    this.fallback,
  });

  /// Shown instead of the placeholder when the screenshot asset doesn't exist
  /// (e.g. an animated illustration), so the user never sees an empty picture.
  final Widget? fallback;

  final StepScreenshot screenshot;
  final String language;
  final double maxHeight;

  /// Change this number to replay the highlight pulse ("Show me again").
  final int pulse;

  /// Tests can inject an in-memory image instead of the bundled asset.
  final ImageProvider? imageOverride;

  @override
  State<ScreenshotGuide> createState() => _ScreenshotGuideState();
}

enum _Load { loading, ready, missing }

class _ScreenshotGuideState extends State<ScreenshotGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  _Load _load = _Load.loading;
  Size? _imageSize;

  ImageProvider get _provider =>
      widget.imageOverride ?? AssetImage(widget.screenshot.asset);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(ScreenshotGuide old) {
    super.didUpdateWidget(old);
    if (old.screenshot.asset != widget.screenshot.asset ||
        old.imageOverride != widget.imageOverride) {
      _load = _Load.loading;
      _resolve();
    }
    if (old.pulse != widget.pulse) _playPulse();
  }

  void _resolve() {
    final stream = _provider.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _detach();
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() {
          _imageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
          _load = _Load.ready;
        });
        _playPulse();
      },
      onError: (error, _) {
        if (mounted) setState(() => _load = _Load.missing);
      },
    );
    _stream = stream..addListener(_listener!);
  }

  void _playPulse() {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!reduceMotion && widget.screenshot.annotations.isNotEmpty) {
      _pulse.forward(from: 0);
    }
  }

  void _detach() {
    if (_listener != null) _stream?.removeListener(_listener!);
  }

  @override
  void dispose() {
    _detach();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (_load) {
      // Scales down to fit whatever space the screen gives the picture.
      _Load.missing when widget.fallback != null => widget.fallback!,
      _Load.missing => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 320,
            child: _Placeholder(asset: widget.screenshot.asset),
          ),
        ),
      ),
      _Load.loading => SizedBox(
        height: widget.maxHeight * 0.6,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.all(
              Radius.circular(AppSpacing.cardRadius),
            ),
          ),
        ),
      ),
      _Load.ready => LayoutBuilder(
        builder: (context, constraints) {
          final displayed = fittedImageSize(
            _imageSize!,
            Size(constraints.maxWidth, widget.maxHeight),
          );
          return Center(
            child: Semantics(
              image: true,
              label: l10n.screenshotLabel(
                widget.screenshot.description.of(widget.language),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppSpacing.cardRadius - 1,
                  ),
                  child: SizedBox.fromSize(
                    size: displayed,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image(
                            image: _provider,
                            fit:
                                BoxFit.fill, // box already has the image aspect
                            gaplessPlayback: true,
                          ),
                        ),
                        for (final a in widget.screenshot.annotations)
                          _AnnotationLayer(
                            rect: annotationRect(a.highlight, displayed),
                            annotation: a,
                            language: widget.language,
                            pulse: _pulse,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    };
  }
}

class _AnnotationLayer extends StatelessWidget {
  const _AnnotationLayer({
    required this.rect,
    required this.annotation,
    required this.language,
    required this.pulse,
  });

  final Rect rect;
  final ScreenshotAnnotation annotation;
  final String language;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final label = annotation.label?.of(language);
    final h = annotation.highlight;
    // Keep labels and markers inside the image near its edges.
    final labelAbove = h.top + h.height > 0.8;
    final labelRight = h.left + h.width / 2 > 0.6;
    final markerInset = h.left < 0.05 || h.top < 0.05;
    return Positioned.fromRect(
      rect: rect,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: pulse,
          builder: (context, child) {
            // Two soft pulses, then rest at full strength.
            final p = pulse.isAnimating ? (1 - (pulse.value * 2 % 1)) : 0.0;
            return CustomPaint(
              painter: _HighlightPainter(glow: p),
              child: child,
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (annotation.marker != null)
                Positioned(
                  left: markerInset ? 4 : -12,
                  top: markerInset ? 4 : -12,
                  child: _Marker(number: annotation.marker!),
                ),
              if (label != null)
                Positioned(
                  left: labelRight ? null : 0,
                  right: labelRight ? 0 : null,
                  top: labelAbove ? null : rect.height + 6,
                  bottom: labelAbove ? rect.height + 6 : null,
                  child: _Label(text: label),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter({required this.glow});
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    if (glow > 0) {
      canvas.drawRRect(
        r.inflate(6 * glow),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = AppColors.highlight.withValues(alpha: 0.25 * glow),
      );
    }
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.highlight,
    );
  }

  @override
  bool shouldRepaint(_HighlightPainter old) => old.glow != glow;
}

class _Marker extends StatelessWidget {
  const _Marker({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) => Container(
    width: 26,
    height: 26,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: AppColors.highlight,
      shape: BoxShape.circle,
    ),
    child: Text(
      '$number',
      textScaler: TextScaler.noScaling,
      style: const TextStyle(
        color: AppColors.onPrimaryAction,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 200),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.highlight,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.onPrimaryAction,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Clearly labelled development placeholder. Never looks like a real app screen.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.image_outlined,
            size: 40,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.screenshotPlaceholderTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.screenshotPlaceholderBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            asset.split('/').last,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall!.copyWith(
              color: AppColors.textTertiary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
