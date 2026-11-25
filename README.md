# Flash Chat

A real-time group chat app built with Flutter and Firebase.

It started as the Flash Chat exercise from a Flutter course, which covers basic text messaging with Firebase Auth and Cloud Firestore. I then extended it with most of the features below.

## Features

- **Email sign-up and login** with Firebase Auth. New users get a verification email and can't sign in until they've confirmed it. There's also a password reset email.
- **Real-time messages** streamed from Cloud Firestore.
- **File sharing:** attach images or PDFs. Images show inline, and PDFs open in an in-app viewer.
- **Voice messages:** tap the mic to record, then cancel or send. Playback shows progress and length, and only one message plays at a time.
- **Delete your own messages** with a long press and a confirmation. Other people's messages can't be deleted from the app.
- **English and Spanish,** with a language switch on the welcome screen.
- Microphone permission handling, with a message if permission is refused.

## Tech

Flutter, Dart, Firebase Auth, Cloud Firestore, Cloudinary (file and audio storage), Provider, Flutter localisation (ARB files), `flutter_sound`, `audioplayers`, `just_audio`, Syncfusion PDF Viewer, `file_picker`, `permission_handler`.

## Security

The app's own checks can be bypassed by anyone who talks to Firestore directly, so the important ones are enforced on the server in [`firestore.rules`](firestore.rules):

| Problem | Fix |
| --- | --- |
| "Only delete your own messages" was enforced only in the app's UI, so a modified client could delete anyone's messages | The rules only let the sender delete a message, and nobody can edit one |
| A client could post as someone else, backdate messages or add any fields | The sender must match the signed-in account, the timestamp must come from the server, and only known fields are allowed |
| A message could point readers' phones at any URL | File and voice note links must point to this app's Cloudinary account |
| No security rules were kept with the code, so access depended on whatever was set in the Firebase console | Reading and posting need a signed-in account with a verified email, and everything outside `messages` is closed |
| Any file type or size could be shared | The app accepts only images and PDFs up to 10 MB, and the rules accept only those file types |
| The login error said whether an email had an account | One message for a wrong email or a wrong password |
| The user's email was written to the debug log | Removed |

**Still open:** uploads use an unsigned Cloudinary preset, so anyone who finds the preset name can upload files to the account, even though the rules stop those files from appearing in the chat. The full fix is to sign uploads on a server (for example a Cloud Function), which needs a paid Firebase plan. Until then, restrict the preset in the Cloudinary console: allow only `jpg, jpeg, png, gif, webp, pdf, aac`, and upload into a dedicated folder.

Everyone also shares one chat room. Private conversations would need per-room access rules.

## Running it

1. Create a Firebase project with Email/Password sign-in and Cloud Firestore, and add its config files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS).
2. Deploy the security rules: `npm install -g firebase-tools`, `firebase login`, then `firebase deploy --only firestore:rules --project <your-project-id>`.
3. Set your own Cloudinary cloud name and unsigned upload preset at the top of `lib/screens/chat_screen.dart`, and change the cloud name in `firestore.rules` to match.
4. Run `flutter pub get`, then `flutter run`.
