# Crop Medic - Flutter app

Futuristic AI plant health scanner. Take a leaf photo, get a diagnosis and advice.
Runs on Android, iOS and web from one codebase.

## 1. Install Flutter
https://docs.flutter.dev/get-started/install  (then run `flutter doctor`)

## 2. Create the project and drop in these files
    flutter create crop_medic
    cd crop_medic

Copy from this folder into the new project, replacing what's there:
- pubspec.yaml      -> crop_medic/pubspec.yaml
- lib/ (all files)  -> crop_medic/lib/

Then:
    flutter pub get

## 3. Android permissions
Open android/app/src/main/AndroidManifest.xml.

Above <application ...> add:
    <uses-permission android:name="android.permission.INTERNET"/>

Inside the <application ...> tag add (only while testing with http://):
    android:usesCleartextTraffic="true"

## 4. iOS (only for iPhone builds)
In ios/Runner/Info.plist add inside <dict>:
    <key>NSCameraUsageDescription</key>
    <string>Crop Medic needs the camera to scan leaves.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Crop Medic needs your photos to pick a leaf image.</string>

## 5. Point the app at your backend
Edit lib/api.dart -> baseUrl
- Android emulator: http://10.0.2.2:8000
- Real phone, same Wi-Fi: http://YOUR-PC-IP:8000
  (start the backend with: uvicorn main:app --host 0.0.0.0 --reload)
- Web / desktop: http://localhost:8000

## 6. Run
    flutter run                 (phone or emulator)
    flutter run -d chrome       (web)

## Next steps
- Scan history (sqflite or drift)
- On-device model with tflite_flutter so it works with no signal
- App icon and splash screen (flutter_launcher_icons)
- Shona and Ndebele UI text (flutter gen-l10n)
- Use https:// when you deploy, and remove usesCleartextTraffic
