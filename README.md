# Smart Lock Project

A smart lock system built with ESP32, Firebase, and Flutter that enables remote control and monitoring of door locks. The system provides real-time status updates, motion detection alerts, and secure access management.

## Features

- Remote lock/unlock control through mobile app
- Real-time lock status monitoring
- Motion detection alerts
- Password protection
- Failed attempt monitoring
- Push notifications for important events

## Components Used

### Hardware
- ESP32 Microcontroller
- PIR Motion Sensor
- SG90 Servo Motor
- LEDs
- LCD I2C Display
- 4x3 Matrix Keypad

### Software
- ESP32 Firmware (Arduino/C++)
- Firebase Realtime Database
- Firebase Cloud Functions (TypeScript)
- Flutter Mobile App

## Project Structure
```
smart-lock-project/
├── firmware/               # ESP32 Arduino code
│   ├── src/
│   ├── include/
│   └── lib/
├── cloud-functions/       # Firebase Cloud Functions
│   └── functions/
└── mobile-app/           # Flutter application
    └── lib/
```

## Setup Guide

### 1. ESP32 Firmware Setup

1. Install Arduino IDE and required libraries:
   - WiFi.h
   - FirebaseESP32
   - ESP32Servo
   - LiquidCrystal_I2C
   - Keypad
   - Preferences

2. Configure WiFi and Firebase credentials in `firmware/include/config.h`:
```cpp
const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";
#define FIREBASE_HOST "your-firebase-host"
#define FIREBASE_AUTH "your-firebase-auth-token"
```

3. Upload the firmware to ESP32

### 2. Firebase Cloud Functions Setup

1. Install dependencies:
```bash
cd cloud-functions/functions
npm install
```

2. Configure Firebase environment variables in `.env`

3. Deploy functions:
```bash
firebase deploy --only functions
```

### 3. Flutter App Setup

1. Install Flutter SDK and dependencies:
```bash
cd mobile-app
flutter pub get
```

2. Configure Firebase settings in `lib/config.dart`

3. Run the app:
```bash
flutter run
```

## Basic Usage

1. Power on the ESP32 device
2. Connect to WiFi network
3. Launch mobile app and log in
4. Use app to control lock status
5. Monitor notifications for alerts

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request
