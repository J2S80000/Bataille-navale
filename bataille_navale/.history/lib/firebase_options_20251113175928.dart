// Configuration Firebase Options
// À générer depuis: https://console.firebase.google.com/project/YOUR_PROJECT/settings/general

class FirebaseOptions {
  static const String apiKey = 'YOUR_API_KEY';
  static const String appId = 'YOUR_APP_ID';
  static const String messagingSenderId = 'YOUR_MESSAGING_SENDER_ID';
  static const String projectId = 'YOUR_PROJECT_ID';
  static const String storageBucket = 'YOUR_STORAGE_BUCKET';
  static const String authDomain = 'YOUR_AUTH_DOMAIN';
  
  // Pour iOS
  static const String iosApiKey = 'YOUR_IOS_API_KEY';
  static const String iosBundleId = 'com.example.battle_navale';
  
  // Pour Android
  static const String androidApiKey = 'YOUR_ANDROID_API_KEY';
  static const String androidPackageName = 'com.example.battle_navale';
}

// Utilisation:
// firebase.FirebaseOptions options = firebase.FirebaseOptions(
//   apiKey: FirebaseOptions.apiKey,
//   appId: FirebaseOptions.appId,
//   messagingSenderId: FirebaseOptions.messagingSenderId,
//   projectId: FirebaseOptions.projectId,
//   storageBucket: FirebaseOptions.storageBucket,
// );
