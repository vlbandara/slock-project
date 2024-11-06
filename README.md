# Smart Lock Project

A comprehensive Smart Lock system integrating ESP32, Firebase, and a Flutter mobile application. This project allows users to remotely control and monitor their smart lock, receive real-time notifications, and ensure enhanced security through motion detection and password protection.

![Smart Lock Diagram](docs/architecture-diagram.png)

## Table of Contents

- [Features](#features)
- [Technologies Used](#technologies-used)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
  - [1. Firmware Setup](#1-firmware-setup)
  - [2. Firebase Cloud Functions](#2-firebase-cloud-functions)
  - [3. Flutter Mobile App](#3-flutter-mobile-app)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Features

- *Remote Control:* Lock and unlock the door via a Flutter mobile app.
- *Real-Time Monitoring:* View lock status, motion detection alerts, and LED states.
- *Notifications:* Receive push notifications for door unlocks and motion detection.
- *Password Protection:* Secure access with customizable passwords.
- *Failed Attempt Tracking:* Monitor and receive alerts on multiple failed access attempts.
- *Motion Detection:* Automatically detect and notify about unauthorized movements near the lock.

## Technologies Used

- *Hardware:*
  - ESP32 Microcontroller
  - PIR Motion Sensor
  - SG90 Servo Motor
  - LEDs (Onboard and Remote)
  - LiquidCrystal I2C Display
  - Keypad (4x3 Matrix)
- *Firmware:* Arduino (C++)
- *Backend:* Firebase Realtime Database, Firebase Cloud Functions
- *Mobile App:* Flutter
- *Cloud Functions Language:* TypeScript

## Project Structure


smart-lock-project/
├── firmware/
│   ├── src/
│   │   └── main.ino
│   ├── include/
│   │   └── config.h
│   ├── lib/
│   └── README.md
├── cloud-functions/
│   ├── functions/
│   │   ├── index.ts
│   │   ├── package.json
│   │   └── tsconfig.json
│   └── README.md
├── mobile-app/
│   ├── lib/
│   │   ├── main.dart
│   │   └── config.dart
│   ├── pubspec.yaml
│   └── README.md
├── docs/
│   ├── architecture-diagram.png
│   └── setup-guide.pdf
├── .gitignore
├── LICENSE
└── README.md


## Prerequisites

### Hardware

- *ESP32 Development Board*
- *SG90 Servo Motor*
- *PIR Motion Sensor*
- *LEDs*
- *LiquidCrystal I2C Display*
- *4x3 Matrix Keypad*
- *Jumper Wires and Breadboard*

### Software

- *Arduino IDE*
- *Node.js and npm*
- *Flutter SDK*
- *Firebase Account*

## Setup Instructions

### 1. Firmware Setup

#### a. Clone the Repository

bash
git clone https://github.com/yourusername/smart-lock-project.git
cd smart-lock-project/firmware


#### b. Install Arduino IDE and Required Libraries

1. *Install Arduino IDE:* Download and install from [Arduino Official Website](https://www.arduino.cc/en/software).

2. *Install Required Libraries:*
   - Open Arduino IDE.
   - Navigate to *Sketch* > *Include Library* > *Manage Libraries*.
   - Install the following libraries:
     - *WiFi.h*
     - *FirebaseESP32*
     - *ESP32Servo*
     - *LiquidCrystal_I2C*
     - *Keypad*
     - *Preferences*

#### c. Configure config.h

Create a config.h file inside the firmware/include/ directory to store your configuration details.

cpp
// firmware/include/config.h
#ifndef CONFIG_H
#define CONFIG_H

// WiFi credentials
const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";

// Firebase credentials
#define FIREBASE_HOST "your-firebase-host"
#define FIREBASE_AUTH "your-firebase-auth-token"

#endif


*Note:* Replace the placeholder values with your actual Wi-Fi and Firebase credentials. *Do not commit this file to GitHub.*

#### d. Update .gitignore

Ensure config.h is excluded from version control by adding it to .gitignore.

gitignore
# Firmware configuration
firmware/include/config.h

# Other exclusions
*.log


#### e. Upload Firmware to ESP32

1. Connect your ESP32 board to your computer via USB.
2. Open firmware/src/main.ino in Arduino IDE.
3. Select the appropriate board and port:
   - *Tools* > *Board* > *ESP32 Dev Module*
   - *Tools* > *Port* > Your ESP32 Port
4. Upload the code by clicking the *Upload* button.

### 2. Firebase Cloud Functions

#### a. Navigate to Cloud Functions Directory

bash
cd smart-lock-project/cloud-functions/functions


#### b. Install Dependencies

bash
npm install


#### c. Configure Environment Variables

Create a .env file to store your Firebase configuration securely.

bash
// cloud-functions/functions/.env
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_AUTH=your_firebase_auth_token
PROJECT_ID=your_project_id
CLIENT_EMAIL=your_client_email
PRIVATE_KEY=your_private_key
FIREBASE_DATABASE_URL=https://your-database-url.firebaseio.com


*Important:* *Do not commit* the .env file to GitHub. Ensure it's listed in .gitignore.

#### d. Deploy Cloud Functions

bash
firebase deploy --only functions


*Note:* Ensure you have Firebase CLI installed and initialized in your project. If not, install it using:

bash
npm install -g firebase-tools
firebase login
firebase init functions


### 3. Flutter Mobile App

#### a. Navigate to Mobile App Directory

bash
cd smart-lock-project/mobile-app


#### b. Install Flutter and Dependencies

1. *Install Flutter SDK:* Follow the [official installation guide](https://flutter.dev/docs/get-started/install).
2. *Get Flutter Packages:*

bash
flutter pub get


#### c. Configure config.dart

Create a config.dart file inside the mobile-app/lib/ directory to store your Firebase configurations.




#### d. Update .gitignore

Ensure config.dart is excluded from version control by adding it to .gitignore.

gitignore
# Flutter configuration
mobile-app/lib/config.dart

# Other exclusions
*.lock


#### e. Run the Flutter App

bash
flutter run


*Note:* Connect your mobile device or start an emulator before running the app.

## Usage

1. *Initial Setup:*
   - Power on the ESP32 device.
   - Ensure it's connected to your Wi-Fi network.
   - Open the mobile app and log in.
   - Pair the app with the ESP32 device.

2. *Controlling the Lock:*
   - Use the app to lock or unlock the door.
   - View real-time status on the app.

3. *Receiving Notifications:*
   - Enable notifications in the app settings.
   - Receive alerts for door unlocks and motion detection.

4. *Changing Password:*
   - Use the keypad on the device or the mobile app to update the password.

5. *Monitoring Failed Attempts:*
   - The system tracks failed access attempts and notifies you if multiple attempts are detected within a short period.

## Contributing

Contributions are welcome! Follow these steps to contribute:

1. *Fork the Repository*
2. *Create a New Branch*

bash
git checkout -b feature/YourFeature


3. *Commit Your Changes*

bash
git commit -m "Add your feature"


4. *Push to the Branch*

bash
git push origin feature/YourFeature


5. *Open a Pull Request*

Please ensure your code follows the project's coding standards and includes relevant tests.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgements

- [Firebase](https://firebase.google.com/)
- [Flutter](https://flutter.dev/)
- [ESP32](https://www.espressif.com/en/products/socs/esp32)
- [Arduino](https://www.arduino.cc/)
- [OpenAI ChatGPT](https://openai.com/blog/chatgpt)# slock-project
 
