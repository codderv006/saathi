# Saathi PoC — Bolna Web Call inside a Flutter Android app

Engineering experiment, not a product. One screen: Start / End voice session, status,
language, an opt-in mic foreground service toggle, and a diagnostic log.

## How it works

```
Flutter app ──POST /session (X-Dev-Token)──▶ server/session_server.mjs ──Bearer bn-key──▶ api.bolna.ai/web-call/session
     │                                                    (127.0.0.1 only)
     │ session JSON (~120 s, single-use SIP/TURN creds)
     ▼
Android WebView ── official @bolna/web-call v3.0.1 (vendored, inlined) ── SIP over WSS + WebRTC ──▶ Bolna agent
```

- The SDK is a **browser** SDK (SIP.js + WebRTC). It runs in a WebView via `loadHtmlString`
  with an `https://` base URL (secure context for `getUserMedia`). The session is minted by
  Dart and handed in using the SDK's documented `session` option.
- The Bolna API key and agent ID exist only in `server/.env` (gitignored).

## Run it on your phone

1. Enable **Developer options → USB debugging** on the phone, and plug it in. Accept the prompt.
   `flutter devices` should now list it.
2. Start the backend (already configured in `server/.env`):
   ```
   node server/session_server.mjs
   ```
3. Make the phone's `localhost:8787` reach this PC over USB:
   ```
   %LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe reverse tcp:8787 tcp:8787
   ```
   (Re-run after every reconnect of the cable.)
4. Run the app:
   ```
   flutter run --dart-define-from-file=poc_config.json
   ```
5. Capture logs while testing (optional): `adb logcat | findstr saathi`

## Device test results — 2026-10-21, Realme 6 (RMX2001), Android 11, WebView 154

| # | Test | Result | Evidence |
|---|------|--------|----------|
| 1 | Connect + hear agent | **Pass** | run `d824e860`: connect→active in 3.4 s, 44.5 s conversation, full transcript in Bolna |
| 2a | English | **Pass** | run `d824e860` (`language: en`), agent understood and guided step by step |
| 2b | Marathi | **Pass** | run `7633c88d` (`language: mr`): user spoke Marathi throughout; agent understood and replied in Marathi, guiding step by step |
| 3a | App switch, no foreground service | **Pass (55 s)** | run `426d43f3`: app in background 12:39:32→12:40:28 while using Uber. Mic never silenced (`silenced: false`, audio mode 3), JS heartbeat steady at 2000 ms, agent audio kept arriving, and the transcript shows the user's speech recognised while backgrounded ("yes it is open", "i've added the local", "done") |
| 3b | App switch, with mic foreground service | Not run | |
| 3c | Screen lock (~21 s, no foreground service) | **Pass** | run `7633c88d`: locked 12:45:43→12:46:04. Mic never silenced, heartbeat steady, agent audio continuous. Bolna transcribed "कुठे टाकायचं ते." at 07:15:55 UTC (12 s into the lock) and answered; call still active after unlock, ended cleanly |
| 4 | End + mic released | **Pass** | both calls: `call-end local-hangup` → `recordings: []`, audio mode back to 0 |

Caveats: one device, one OEM ROM, Android 11, about 1 minute in the background. Not covered:
longer background/lock periods (minutes), Android 12–15, other OEMs, low-memory kills,
and the mic foreground service path (3b).

What to read in the log during test 3:

- `[android] {type: recording, configs: [{silenced: true}]}` → Android is feeding the app
  silence (background mic restriction). `silenced: false` → mic still live.
- `[heartbeat] ... vis=hidden gap=…ms agentAudio samples=N avg=…` → JS still running in
  the background (gap ≈ 2000 ms) and agent audio still arriving (samples > 0, avg > 0).
  Large gaps = WebView timers throttled.
- `[voice] call-end {reason: remote-hangup}` while `lifecycle=paused` → connection dropped
  in the background.
- `[lifecycle] paused/resumed` and `[android] onStop/onResume` → Flutter vs Activity lifecycle.

## Security limitations (temporary, local PoC only)

- The session server is plain HTTP, bound to `127.0.0.1`, reached by the phone through
  `adb reverse` over USB. Not reachable from the LAN or internet unless you change `HOST`.
- Access control is a shared `X-Dev-Token` baked into the debug build; anyone with the APK
  could extract it. Fine for one developer's device; **not** acceptable for production
  (needs real user auth, e.g. Firebase ID tokens, plus HTTPS).
- Simple in-memory rate limit: 10 mints/minute.
- Cleartext HTTP is allowed in **debug builds only** (`android/app/src/debug/AndroidManifest.xml`).
- Minted sessions contain one-time SIP/TURN credentials; the server logs only `run_id`.
- `../api.txt` (outside this folder) also holds the real key in plain text — delete it or
  keep it out of any repository.

## Files

- `lib/voice/webview_bolna_adapter.dart` — WebView host for the SDK, JS↔Dart bridge
- `assets/bolna/call.html`, `assets/bolna/bolna-web-call.min.js` — page + official SDK v3.0.1
  (sha256 `85242481ba962e225cb2052de55a80579e469ff548082bb1ad4040b3f1556c46`)
- `lib/voice/session_client.dart` — calls the local backend
- `android/.../MainActivity.kt` — permissions, audio diagnostics (AudioRecordingCallback)
- `android/.../VoiceSessionService.kt` — opt-in `microphone` foreground service for test 3b
- `server/session_server.mjs` — trusted mint endpoint (no dependencies)

Parked for later (not built): workflow engine + tests and Firebase backend in `../saathi_parked/`.
