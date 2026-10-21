import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/saathi_logo.dart';
import '../../l10n/app_localizations.dart';

/// Single calm intro screen. No permission prompts here — the microphone is only
/// requested when the user first starts talking.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = AppScope.of(context).settings;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    const SaathiLogo(),
                    const SizedBox(height: AppSpacing.xl),
                    const _GuideIllustration(),
                    const SizedBox(height: AppSpacing.xl),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.onboardingTitle,
                        style: theme.textTheme.displaySmall,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.onboardingBody,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.chooseLanguage, style: theme.textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.xs),
                    const LanguageToggle(),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            l10n.privacyNote,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.xs,
                AppSpacing.pagePadding,
                AppSpacing.md,
              ),
              child: PrimaryButton(
                label: l10n.getStarted,
                onPressed: settings.completeOnboarding,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple drawing of the idea: a phone with one highlighted target, and a voice bubble.
class _GuideIllustration extends StatelessWidget {
  const _GuideIllustration();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: CustomPaint(painter: _IllustrationPainter()),
    ),
  );
}

class _IllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    final white = Paint()..color = AppColors.background;

    // Phone.
    final phone = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.40, size.height * 0.55),
        width: 92,
        height: 150,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(phone, white);
    canvas.drawRRect(phone, ink);
    final inner = phone.outerRect.deflate(12);
    final line = Paint()..color = AppColors.border;
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inner.left,
            inner.top + 8 + i * 18,
            inner.width * (i == 1 ? 0.7 : 1),
            8,
          ),
          const Radius.circular(4),
        ),
        line,
      );
    }
    // Highlighted target on the phone.
    final target = RRect.fromRectAndRadius(
      Rect.fromLTWH(inner.left, inner.top + 70, inner.width, 22),
      const Radius.circular(8),
    );
    canvas.drawRRect(target, Paint()..color = AppColors.lavender);
    canvas.drawRRect(
      target.inflate(3),
      Paint()
        ..color = AppColors.lavenderStrong
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // Voice bubble.
    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.56, size.height * 0.14, 96, 56),
      const Radius.circular(20),
    );
    canvas.drawRRect(bubble, white);
    canvas.drawRRect(bubble, ink);
    final bars = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const heights = [10.0, 22.0, 14.0, 26.0, 12.0];
    final cx = bubble.outerRect.center;
    for (var i = 0; i < heights.length; i++) {
      final x = cx.dx - 24 + i * 12;
      canvas.drawLine(
        Offset(x, cx.dy - heights[i] / 2),
        Offset(x, cx.dy + heights[i] / 2),
        bars,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
