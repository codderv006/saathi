import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../guided_workflow/data/guide_catalog.dart';
import '../guided_workflow/domain/workflow.dart';
import '../guided_workflow/presentation/app_illustration.dart';
import '../guided_workflow/presentation/screenshot_guide.dart';

/// The picture for a step: the real (redacted) screenshot with highlights when we
/// have one, otherwise an animated illustration in the app's colours. Never empty.
class GuideVisual extends StatelessWidget {
  const GuideVisual({
    super.key,
    required this.step,
    required this.app,
    required this.language,
    required this.maxHeight,
  });

  final WorkflowStep step;
  final AppInfo? app;
  final String language;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final illustration = AppIllustration(
      visual: step.visual ?? const StepVisual('info'),
      appName: app?.name ?? 'Saathi',
      color: Color(app?.color ?? AppColors.lavenderStrong.toARGB32()),
      accent: Color(app?.accent ?? AppColors.lavender.toARGB32()),
      maxHeight: maxHeight,
    );
    final shot = step.screenshot;
    if (shot == null) return illustration;
    return ScreenshotGuide(
      screenshot: shot,
      language: language,
      maxHeight: maxHeight,
      fallback: illustration,
    );
  }
}
