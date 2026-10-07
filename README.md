# Stride

A free and open-source step tracker for Android.

Stride reads your step, distance, and calorie data from Health Connect and presents it in a clean, modern dashboard — entirely on your device. No accounts, no ads, no trackers, no analytics, no network calls. Your health data never leaves your phone.

## Features

- **Daily step goal** with an expressive Material 3 progress ring
- **Distance, calorie, and active-minute stats** alongside steps
- **7-day activity chart** to spot trends at a glance
- **365-day history** with week, month, and year totals
- **Goal & body-stat settings** — customize your daily step goal, weight, and stride length
- **Metric / imperial units** — switch between km and miles anytime
- **Light / dark / system theme** with Material 3 dynamic color support
- **Automatic background sync** every 6 hours via WorkManager
- **One-tap backfill** — import up to 365 days of history the first time you connect

## Privacy

100% on-device: Health Connect data never leaves the phone. There are no accounts, no ads, no trackers, no analytics — the app makes no network calls at all.

## Requirements

- Android 8.0 (API 26) or higher
- Health Connect: built into Android 14 and above; on Android 8–13 install the **Health Connect** app from the Play Store first

## Build with Android Studio

1. Install [Android Studio](https://developer.android.com/studio)
2. Open the `stride` folder in Android Studio
3. Let Gradle sync finish
4. Run the `app` configuration on a device or emulator

A debug APK also builds from the command line with `./gradlew assembleDebug`.

## Get an APK without Android Studio

Push the project to a GitHub repository's `main` branch (or open a pull request against it). The included GitHub Actions workflow builds a debug APK on every push to `main` and on pull requests, then uploads it as the `stride-debug-apk` artifact. Download it from the **Actions** tab of your repository.

## Health Connect setup

1. Open Stride and walk through the onboarding flow
2. When prompted, grant the **Steps**, **Distance**, and **Calories** permissions in Health Connect
3. Optionally tap the backfill option to import up to 365 days of history

On Android 13 and below, install the **Health Connect** app from the Play Store before granting permissions.

## Project structure

```
app/src/main/java/org/stride/tracker/
├── data
│   ├── local   # Room database: entities, DAOs
│   ├── prefs   # DataStore settings
│   ├── health  # Health Connect client, backfill
│   ├── repo    # Repository layer
│   ├── work    # WorkManager periodic sync worker
│   └── di      # Dependency injection
└── ui
    ├── theme        # Material 3 Expressive theme
    ├── navigation   # Navigation Compose routes
    ├── dashboard    # Home screen: progress ring, stats, chart
    ├── history      # History screen: 365 days, week/month/year totals
    ├── settings     # Goal, body stats, units, theme
    └── onboarding  # Permissions & backfill flow
```

## Tech stack

- Kotlin + Jetpack Compose (BOM)
- Material 3 Expressive design (stable M3 APIs + dynamic color)
- Room for history, DataStore for settings, WorkManager for periodic sync
- Navigation Compose
- Health Connect client (on-device read-only)

Health data estimation fallbacks (used when Health Connect doesn't report a value):

- Calories: `steps × 0.045 × (weightKg / 70)`
- Distance (meters): `steps × strideLength / 100`
- Active minutes: `steps / 120`

## License

GNU General Public License v3.0 only — see [LICENSE](LICENSE).

## Contributing

Issues and pull requests are welcome. Stride's core promise is that it stays tracker-free and fully on-device — contributions should keep it that way.
