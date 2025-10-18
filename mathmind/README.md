# MathMind

MathMind is an AI-guided math tutor built with Flutter. The app personalises explanations by age/grade, evaluates learner understanding, schedules two-day retention reviews, and surfaces parent-ready progress reports for premium subscribers.

## Feature Highlights

- Adaptive lessons: GPT-4o powered explanations tuned to learner grade and name.
- Understanding checks: learners re-explain concepts and receive instant scoring & feedback.
- Retention loop: two-day review queue with Firestore-backed history tracking.
- Concept detection: paste a problem statement to auto-tag the relevant concept.
- Speech support: dictation for learner explanations + text-to-speech playback.
- Subscription tiers (Free, Basic, Premium) with RevenueCat integration scaffolding.
- Premium visual aids: DALL·E endpoint wrappers ready for diagram generation.

## Tech Stack

- Flutter (Material 3, Provider state management)
- Firebase Core, Auth, Firestore, Messaging, Analytics, Functions
- OpenAI GPT-4o via `openai_dart` plus DALL·E image API
- RevenueCat purchases via `purchases_flutter`
- Voice: `speech_to_text` + `flutter_tts`

## Project Structure

```
lib/
  bootstrap.dart                 // dotenv + Firebase init
  src/
    app.dart                     // Provider wiring + router
    core/                        // Shared services & config
    features/
      auth/                      // Firebase Auth glue
      dashboard/                 // Bottom-nav shell
      home/                      // Overview & actions
      lessons/                   // Session orchestration & UI
      retention/                 // 2-day review workflow
      subscription/              // RevenueCat-aware state
      profile/                   // Account management
      splash/                    // Bootstrap screen
    navigation/app_router.dart   // Named route factory
```

## Environment Variables

Copy `.env.example` to `.env` in the project root and fill in the secrets:

```
OPENAI_API_KEY=sk-...
FIREBASE_CONFIG={"apiKey":"...","appId":"...","messagingSenderId":"...","projectId":"...","storageBucket":"..."}
FCM_SERVER_KEY=...
GOOGLE_CLOUD_API_KEY=
REVENUECAT_KEY=
```

> The `FIREBASE_CONFIG` value should be a JSON object matching the `FirebaseOptions` required for your project (use `flutterfire configure` to generate precise values).

## Running Locally

```bash
flutter pub get
flutter run
```

### First-time setup checklist

1. Configure Firebase for each platform (Android/iOS/web) and include the generated config files.
2. Ensure Developer Mode is enabled on Windows for symlink support when targeting desktop.
3. If RevenueCat is not yet configured, leave `REVENUECAT_KEY` blank—the subscription UI will stay in a mock state.
4. Test OpenAI connectivity by starting a lesson; fallback explanations are generated when the API key is missing.

## Next Steps

- Wire RevenueCat entitlements to match `basic` and `premium` plans.
- Generate Firebase Cloud Functions for retention reminder push notifications.
- Expand premium-only visual explanations to render DALL·E responses within the lesson flow.
