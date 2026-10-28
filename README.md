# Saathi

Voice-first helper for people (often older parents) who are not confident with phone
apps. Tap the mic and ask anything about **Ola, Uber, Rapido** (rides), **Google Pay,
PhonePe** (UPI payments) or **WhatsApp**, in **English or Marathi**. Saathi talks you
through it while the screen shows the matching step: a real redacted screenshot where we
have one, otherwise an animated illustration of the app. It never taps, types, pays or
books for you, and it politely declines questions about anything else.

## Demo

[![Saathi demo video: a voice companion that helps parents use their phone](https://img.youtube.com/vi/dRGNC5Cv28k/maxresdefault.jpg)](https://youtu.be/dRGNC5Cv28k)

▶ [Watch the demo on YouTube](https://youtu.be/dRGNC5Cv28k) (2.5 min)

## How it works

```
Phone (Flutter)                        PC (dev)                         Bolna
 tap mic ─ POST /session ───────────▶ session_server.mjs ─ mint ─────▶ voice agent (EN/MR)
 WebView + @bolna/web-call ◀═══════════════ WebRTC call ═════════════▶      │
 guide screen ◀─ /events long-poll ── relay ◀─ /tool ◀─ Cloudflare tunnel ◀─┘ saathi_guide tool
```

The agent can only *request* guide actions (`show_topic`, `step_done`, `go_back`,
`outcome`, `close_topic`). The app's workflow engine applies them: current step only, no
skipping, a ride is "booked" only from the user's own answer.

## Coverage (assets/guides/catalog.json)

| Apps | Topics |
|---|---|
| Ola, Uber, Rapido | book a ride (new user from Play Store, or signed in), cancel, vehicle number, call/message driver, fare, driver ETA, ride OTP/PIN, paying, sharing the trip and SOS |
| Google Pay, PhonePe | link bank + UPI PIN, pay a phone number, scan QR, check balance, add credit/RuPay card, receive money, history, failed payments, PIN/OTP safety |
| WhatsApp | send a message, voice message, type in Marathi (keyboard language), save/rename contact, profile photo (DP), status, what communities are and why, joining one, video call, photos, blocking spam |

Real screenshots exist for Ola/Uber/Rapido ride booking (`tools/build_screenshots.py`
from screen recordings, personal data blurred). Every other step uses an animated vector
illustration (`app_illustration.dart`), so the screen is never empty.

## Status (2026-10-22)

| Area | State |
|---|---|
| Mic-first UI (orb, bilingual invite, live call pill, step cards, browse) | Done, on device |
| 6 apps / 29 topics, EN + MR, animated illustrations | Done, 64 tests |
| Voice-driven screen (`saathi_guide` tool) | Ride flow verified live 2026-10-21; general topics need a spoken test |
| Agent scope (only these apps, declines others) | Prompt applied to Bolna agent; needs a spoken test |
| Firebase (Spark): anonymous auth + Firestore cloud copy, tested rules | Done |
| Marathi copy review by a native speaker | Pending |

## Run on a phone

```
powershell -ExecutionPolicy Bypass -File dev.ps1   # phone forward + server + tunnel + agent URL
flutter run --dart-define-from-file=poc_config.json
```

Without `poc_config.json` the app still runs; voice shows "Voice isn't set up on this
phone yet", progress stays on the phone only, and the guides work normally.

Firebase values in `poc_config.json` come from `android/app/google-services.json`
(both gitignored). Progress is saved on the phone first and copied to Firestore in the
background; offline use never blocks a step. Anonymous accounts don't survive an
uninstall, so restoring after a reinstall needs real sign-in later.

Checks: `flutter analyze` · `flutter test` (60 tests) · `cd firebase && npm test` (rules, needs Java) ·
`node --check server/session_server.mjs`. Deploy rules: `cd firebase && npm run deploy:rules`.

## Structure

```
lib/
  app/                 app.dart (root, hosts the voice WebView), app_scope.dart, theme/
  core/                config, services (settings, android bridge, debug log), widgets
  features/
    onboarding/        single intro screen + language
    home/              voice card, ride guide, app picker, setup question
    guided_workflow/
      domain/          workflow model, engine (pure), controller, store port
      data/            ride_workflow.dart (Ola/Uber/Rapido content), registry, local store
      presentation/    guide screen, screenshot viewer + annotations, help/copy sheets, completion
    voice_session/     VoiceSessionService port, Bolna WebView implementation, UI
    settings/, diagnostics/   (diagnostics = the original PoC debug screen)
  l10n/                app_en.arb, app_mr.arb
assets/
  bolna/               official @bolna/web-call v3.0.1 (vendored) + call page
  workflows/<app>/     screenshots — see assets/workflows/MANIFEST.md
server/                local session-mint backend (dev only)
firebase/              firestore.rules + emulator rules tests
tools/extract_frames.py   pull candidate screenshots out of screen recordings
docs/                  agent prompt, PoC voice results
```

## Key rules (enforced in `workflow_engine.dart`, covered by tests)

- A step advances only on explicit confirmation of *that* step; duplicates are rejected.
- Repeat / help / simpler never change the step. Back keeps confirmation history.
- Reaching the last step is not success: the user must report the outcome.
- Voice "done" only raises an on-screen confirmation; the agent can't move the step.
- A failed save never advances. Revision checks stop stale writes.

## Security limitations (dev setup)

The session server is plain HTTP on `127.0.0.1`, reached over USB via `adb reverse`, with a
shared token baked into the debug build. Fine for one developer phone; production needs
real auth (Firebase ID tokens) and HTTPS (the parked Cloud Function). The Bolna key lives
only in `server/.env` (gitignored).
