# Student Information

A Flutter student-record app with email/password and Google sign-in, a simple
Home/Students/Account navigation bar, and student records stored in Firestore.
The app supports college year levels, semester/year, active and dropped
statuses, record history, and a per-account theme preference.

## Firebase setup

In the Firebase project configured in `lib/firebase_options.dart`:

1. Enable **Email/Password** and **Google** under Authentication > Sign-in
   method. Under Authentication > Settings > Authorized domains, add
   `127.0.0.1` for local web runs served from that address (domain only; do not
   include `http://` or the port). If you run the app at `localhost`, ensure
   `localhost` is listed instead.
2. Add the Android app's SHA-1 and SHA-256 signing certificate fingerprints in
   Project settings. Then download the refreshed `google-services.json` and
   replace `android/app/google-services.json`. It must include the generated
   web OAuth client for Google Sign-In.
3. Create a Firestore database and deploy the owner-only rules with
   `firebase deploy --project flutter-firebase-app-23774 --only firestore:rules`.

Student records and activity history are saved under
`users/{uid}/students/{studentId}` and `users/{uid}/activity/{activityId}`.
Theme preferences are saved in the user's Firestore document. The app does not
upload photos or use Firebase Storage. Both email account creation and Google
sign-in use Firebase Authentication; Google sign-in requires the Firebase
Console setup above.

## Build Android APK

Install the Android SDK, set `ANDROID_HOME` (or update `android/local.properties`
to its `sdk.dir`), then run:

```shell
flutter pub get
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.
