# Saathi

Voice-first guide that helps people (often older parents) use everyday apps themselves,
one step at a time, in **English and Marathi**. First milestone: **booking a ride with
Ola, Uber or Rapido**, starting either from a fresh install (Play Store → sign-up → OTP →
location → booking) or for someone already signed in.

Saathi never taps, types, books or pays inside another app. It explains, shows a
screenshot, and waits for the user to confirm.

## Status (2026-10-21)

| Area | State |
|---|---|
| App shell, design system, EN/MR localisation | Done, device-tested (Realme 6, Android 11) |
| Ride guides: Ola / Uber / Rapido × fresh-install / signed-in | Done, device-tested with placeholders |
| Workflow rules (explicit confirm, no skipping, history, pause, honest outcome) | Done, unit + widget tested |
| Local progress save/restore (incl. force-kill) | Done, device-tested |
| Bolna voice (WebView SDK) inside the app | Done, device-tested: connect, MR session, background 20 s, return, mic released |
| Real screenshots + annotations | **Waiting for your recordings** |
| Agent prompt using step context | Written (`docs/bolna_agent_prompt.md`), **not yet applied** in Bolna |
| Firebase (Spark, free): anonymous auth + Firestore cloud copy | Done, device-tested (project `saathi-b82ed`): sign-in, phone-first save with background cloud sync, read-back IN SYNC through live rules. Rules: 10 emulator tests. No Cloud Functions (Blaze-only) |

## Run on a phone

```
node server/session_server.mjs                         # keep running (reads server/.env)
%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe reverse tcp:8787 tcp:8787
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
