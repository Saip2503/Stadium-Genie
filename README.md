# StadiumGenie

StadiumGenie is a Flutter Web assistant for FIFA 2026 stadium fans. It combines mock stadium operations data, multilingual Gemini-powered chat, accessibility-aware routing, Firebase Google sign-in, and a light Stitch-inspired UI.

## What it does

- Recommends the shortest food, restroom, merch, and gate queues
- Responds in the user's language
- Filters guidance for wheelchair and sensory-friendly needs
- Shows a live-style dashboard from mock stadium JSON
- Supports Google sign-in through Firebase Auth

## Tech Stack

- Flutter Web
- Riverpod
- Firebase Auth
- Google Sign-In
- Google Gemini API
- `flutter_dotenv`

## Project Structure

- `lib/main.dart` - app bootstrap, Firebase init, routing
- `lib/screens/` - home, chat, login, and settings screens
- `lib/services/` - Gemini, auth, and mock data services
- `lib/providers/` - chat and settings state
- `lib/models/` - stadium and message models
- `assets/data/stadium_status.json` - mock stadium operations data
- `assets/images/` - stadium hero image and app logo

## Environment Setup

Create a `.env` file at the project root:

```env
AI_API_KEY=your_gemini_api_key_here
```

The app also accepts `GEMINI_API_KEY` and `API_KEY`, but `AI_API_KEY` is the preferred key in this repo.

## Firebase Setup

This project includes web Firebase config in `lib/firebase_options.dart`.

If Google sign-in shows a `configuration-not-found` error:

1. Open the Firebase Console for project `stadium-genie`
2. Enable Authentication
3. Enable the Google sign-in provider
4. Confirm the web app configuration matches the generated options file

## Run Locally

```bash
flutter pub get
flutter run -d chrome
```

## Test

```bash
flutter test
flutter analyze
```

## Notes

- The app uses mock stadium data for queue times and accessibility info.
- The UI defaults to light mode to match the Stitch design direction.
- If the Gemini key is missing, the app keeps running with simulated fallback responses.
