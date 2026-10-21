# Ride-app screenshot manifest (Ola, Uber, Rapido)

Put screenshots in `assets/workflows/<app>/` named `<app>_<step id>.png`
(e.g. `assets/workflows/uber/uber_enter_otp.png`). Until a file exists, the app shows a
clearly labelled placeholder for that step. Keep originals unedited: highlights are drawn
by the app as a separate layer (`ScreenshotGuide`).

| Step id | Guide | What the screenshot should show |
|---|---|---|
| `install_app` | new users | The app's Play Store page with the Install button |
| `open_app` | both | Phone home screen / app drawer with the app icon |
| `enter_phone` | new users | Sign-up screen asking for the mobile number |
| `enter_otp` | new users | Screen asking for the SMS code (**blur any real code**) |
| `profile_details` | new users | Name / email / terms screen, if the app shows one |
| `allow_location` | new users | Android location permission pop-up |
| `find_locations` | both | Main booking screen with pickup and destination |
| `enter_destination` | both | Destination search with typed text and suggestions |
| `check_locations` | both | Screen showing the chosen pickup and destination |
| `review_rides` | both | List of ride types (bike / auto / cab etc.) |
| `check_fare` | both | Fare and trip details for the chosen ride |
| `decide_booking` | both | Screen with the book / confirm button |
| `confirm_outcome` | both | Screen the app shows after a ride is booked |

Guidelines:
- PNG, portrait, full phone screenshot (no frame). Any resolution; the app scales it.
- Remove or blur personal data (names, phone numbers, home address, OTPs) first.
- Annotations go in `lib/features/guided_workflow/data/ride_workflow.dart`
  (`StepScreenshot.annotations`) as fractions of the image:
  `NormalizedRect(left, top, width, height)`. A box starting 10% from the left, 30% down,
  80% wide and 8% tall is `NormalizedRect(0.10, 0.30, 0.80, 0.08)`.
