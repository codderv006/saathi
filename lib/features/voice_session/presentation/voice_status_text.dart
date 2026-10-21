import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/voice_session_service.dart';

/// Plain-language title, explanation and icon for every voice state.
class VoiceStatusText {
  const VoiceStatusText(this.title, this.hint, this.icon);

  final String title;
  final String hint;
  final IconData icon;

  factory VoiceStatusText.of(AppLocalizations l10n, VoiceStatus status) =>
      switch (status.phase) {
        VoicePhase.idle => VoiceStatusText(
          l10n.voiceIdle,
          l10n.voiceIdleHint,
          Icons.mic_none_rounded,
        ),
        VoicePhase.requestingPermission => VoiceStatusText(
          l10n.voiceRequestingPermission,
          l10n.voiceRequestingPermissionHint,
          Icons.mic_none_rounded,
        ),
        VoicePhase.connecting => VoiceStatusText(
          l10n.voiceConnecting,
          l10n.voiceConnectingHint,
          Icons.sync_rounded,
        ),
        VoicePhase.listening => VoiceStatusText(
          l10n.voiceListening,
          l10n.voiceListeningHint,
          Icons.mic_rounded,
        ),
        VoicePhase.speaking => VoiceStatusText(
          l10n.voiceSpeaking,
          l10n.voiceSpeakingHint,
          Icons.graphic_eq_rounded,
        ),
        VoicePhase.muted => VoiceStatusText(
          l10n.voiceMuted,
          l10n.voiceMutedHint,
          Icons.mic_off_rounded,
        ),
        VoicePhase.ended => VoiceStatusText(
          l10n.voiceEnded,
          l10n.voiceEndedHint,
          Icons.call_end_rounded,
        ),
        VoicePhase.disconnected => VoiceStatusText(
          l10n.voiceDisconnected,
          l10n.voiceDisconnectedHint,
          Icons.portable_wifi_off_rounded,
        ),
        VoicePhase.failed => VoiceStatusText(
          l10n.voiceFailed,
          switch (status.failure) {
            VoiceFailure.microphoneDenied => l10n.errMicDenied,
            VoiceFailure.notConfigured => l10n.errNotConfigured,
            VoiceFailure.network => l10n.errNetwork,
            VoiceFailure.busy => l10n.errBusy,
            VoiceFailure.unavailable => l10n.errUnavailable,
            VoiceFailure.generic || null => l10n.errGeneric,
          },
          status.failure == VoiceFailure.microphoneDenied
              ? Icons.mic_off_rounded
              : Icons.error_outline_rounded,
        ),
      };
}
