import 'package:firebase_core/firebase_core.dart';

// Client configuration is supplied by a registered Firebase app at build time.
// These are public app identifiers, never service-account credentials.
const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const firebaseSenderId = String.fromEnvironment('FIREBASE_SENDER_ID');
const firebaseAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

bool get firebaseConfigured =>
    firebaseApiKey.isNotEmpty &&
    firebaseAppId.isNotEmpty &&
    firebaseProjectId.isNotEmpty &&
    firebaseSenderId.isNotEmpty;

FirebaseOptions get firebaseOptions => FirebaseOptions(
  apiKey: firebaseApiKey,
  appId: firebaseAppId,
  messagingSenderId: firebaseSenderId,
  projectId: firebaseProjectId,
  authDomain: firebaseAuthDomain.isEmpty
      ? '$firebaseProjectId.firebaseapp.com'
      : firebaseAuthDomain,
);
