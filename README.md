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

## Security notes

Things I'd change before real users:

- The "only delete your own messages" rule is enforced in the app's UI. It also needs to be enforced in Firestore security rules, otherwise a modified client could delete anyone's messages.
- Uploads use an unsigned Cloudinary preset. That's fine for a demo, but anyone who finds the preset can upload files. A production version would sign uploads on a server (for example a Cloud Function) and check file type and size there.
- Everyone shares one chat room. Private conversations would need per-room access rules.

## Running it

1. Create a Firebase project with Email/Password sign-in and Cloud Firestore, and add its config files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS).
2. Set your own Cloudinary cloud name and unsigned upload preset at the top of `lib/screens/chat_screen.dart`.
3. Run `flutter pub get`, then `flutter run`.
