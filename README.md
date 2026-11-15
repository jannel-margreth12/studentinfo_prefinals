# Student Information

A Flutter student-record app with email/password and Google sign-in, a simple
Home/Students/Account navigation bar, and student records stored in Firestore.

## Firebase setup

In the Firebase project configured in `lib/firebase_options.dart`:

1. Enable **Email/Password** and **Google** under Authentication > Sign-in
   method.
2. Add the Android app's SHA-1 and SHA-256 signing certificate fingerprints in
   Project settings. Then download the refreshed `google-services.json` and
   replace `android/app/google-services.json`. It must include the generated
   web OAuth client for Google Sign-In.
3. Create a Firestore database and deploy the included owner-only rules with
   `firebase deploy --only firestore:rules`.

Student records are saved under `users/{uid}/students/{studentId}`. Both email
account creation and Google sign-in create Firebase Authentication accounts;
Google sign-in requires the Firebase Console setup above.

## Build Android APK

Install the Android SDK, set `ANDROID_HOME` (or update `android/local.properties`
to its `sdk.dir`), then run:

```shell
flutter pub get
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.
