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
AI_MODEL=gemini-3.5-flash
```

The app also accepts `GEMINI_API_KEY`, `API_KEY`, and `GEMINI_MODEL`, but `AI_API_KEY` and `AI_MODEL` are the preferred names in this repo. Use `gemini-3.1-flash-lite` for a lighter fallback model if your API quota requires it.

## Firebase Setup

This project includes web Firebase config in `lib/firebase_options.dart`.

If Google sign-in shows a `configuration-not-found` error:

1. Open the Firebase Console for project `stadium-genie`
2. Enable Authentication
3. Enable the Google sign-in provider
4. Enable Anonymous sign-in if you want judges to try the app without Google
5. Add the deployed Vercel domain to Authentication > Settings > Authorized domains:

```text
stadium-genie-jet.vercel.app
```

6. Confirm the web app configuration matches the generated options file

## Vercel Deployment

This repo includes `vercel.json`, `package.json`, and `scripts/write_env_for_vercel.js` for Flutter Web deployment.

In Vercel project settings, add this environment variable:

```env
AI_API_KEY=your_gemini_api_key_here
AI_MODEL=gemini-3.5-flash
```

Vercel runs:

```bash
npm run vercel-build
```

The build script creates the `.env` asset from Vercel environment variables, installs Flutter stable if needed, builds with `flutter build web --release --base-href /`, and serves `build/web`.

The Vercel rewrite sends all paths back to `index.html`, so both of these routes should load:

```text
https://stadium-genie-jet.vercel.app/
https://stadium-genie-jet.vercel.app/#/chat
```

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
