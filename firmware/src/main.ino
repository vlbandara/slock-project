#include <WiFi.h>
#include <FirebaseESP32.h>
#include <addons/TokenHelper.h>
#include <ESP32Servo.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <Keypad.h>
#include <Preferences.h>

// WiFi credentials
const char *ssid = "Yourssid";
const char *password = "yourpass";

// Firebase credentials
#define FIREBASE_HOST "yourhost"
#define FIREBASE_AUTH "yourauth"

// Define Firebase Data object
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Servo setup
Servo sg90;
#define PIN_SG90 13
const int lockedPosition = 0;
const int unlockedPosition = 90;

// LCD setup
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Keypad setup
const byte ROWS = 4;
const byte COLS = 3;
char keys[ROWS][COLS] = {
    {'1', '2', '3'},
    {'4', '5', '6'},
    {'7', '8', '9'},
    {'*', '0', '#'}};
byte rowPins[ROWS] = {4, 16, 17, 5};
byte colPins[COLS] = {18, 19, 23};
Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

// Password setup
String passwordLock = "1234"; // Default password
String input = "";

// PIR sensor and LED setup
#define PIR_PIN 14
#define ONBOARD_LED_PIN 27
#define REMOTE_LED_PIN 15

// State variables
bool remoteLedState = false;
bool lockState = false;
bool motionDetected = false;

// Timers for periodic tasks
unsigned long lastWiFiCheck = 0;
unsigned long lastFirebaseUpdate = 0;
unsigned long lastMotionCheck = 0;
const unsigned long wifiCheckInterval = 30000;     // Check WiFi every 30 seconds
const unsigned long firebaseUpdateInterval = 5000; // Update Firebase every 5 seconds
const unsigned long motionCheckInterval = 1000;    // Check motion every second

// Preferences for storing data
Preferences preferences;

void setup()
{
  Serial.begin(115200);
  preferences.begin("smartlock", false);

  pinMode(ONBOARD_LED_PIN, OUTPUT);
  pinMode(REMOTE_LED_PIN, OUTPUT);
  pinMode(PIR_PIN, INPUT);

  // Servo setup
  sg90.setPeriodHertz(50);
  sg90.attach(PIN_SG90, 500, 2400);

  // LCD setup
  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.print("Initializing...");

  // Load saved password
  passwordLock = preferences.getString("password", passwordLock);

  // Keypad setup - Set debounce time to 0 for faster response
  keypad.setDebounceTime(0);

  // Initial connection
  connectWiFi();
  initFirebase();

  // Lock the door initially
  lockDoor();

  lcd.clear();
  lcd.print("Enter Password:");
}

void loop()
{
  unsigned long currentMillis = millis();

  // Priority 1: Check keypad input
  checkKeypad();

  // Priority 2: Handle motion detection
  if (currentMillis - lastMotionCheck >= motionCheckInterval)
  {
    checkMotion();
    lastMotionCheck = currentMillis;
  }

  // Lower priority tasks
  if (currentMillis - lastWiFiCheck >= wifiCheckInterval)
  {
    checkWiFiConnection();
    lastWiFiCheck = currentMillis;
  }

  if (currentMillis - lastFirebaseUpdate >= firebaseUpdateInterval)
  {
    if (Firebase.ready())
    {
      updateFirebaseStates();
      handleFirebaseData();
    }
    lastFirebaseUpdate = currentMillis;
  }

  // No delay in the main loop to keep it responsive
}

void connectWiFi()
{
  WiFi.begin(ssid, password);
  Serial.print("Connecting to Wi-Fi");
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20)
  {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  if (WiFi.status() == WL_CONNECTED)
  {
    Serial.println("\nConnected to WiFi");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
  }
  else
  {
    Serial.println("\nFailed to connect to WiFi");
  }
}

void initFirebase()
{
  config.database_url = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Serial.println("Connecting to Firebase...");
  int attempts = 0;
  while (!Firebase.ready() && attempts < 20)
  {
    Serial.print(".");
    delay(500);
    attempts++;
  }
  if (Firebase.ready())
  {
    Serial.println("\nConnected to Firebase");
  }
  else
  {
    Serial.println("\nFailed to connect to Firebase");
  }
}

void checkKeypad()
{
  if (keypad.getKeys())
  {
    for (int i = 0; i < LIST_MAX; i++)
    {
      if (keypad.key[i].stateChanged)
      {
        switch (keypad.key[i].kstate)
        {
        case PRESSED:
          handleKeypadInput(keypad.key[i].kchar);
          break;
        }
      }
    }
  }
}

void handleKeypadInput(char key)
{
  if (key == '#')
  {
    checkPassword();
  }
  else if (key == '*')
  {
    input = "";
    updateLCD();
  }
  else
  {
    input += key;
    updateLCD();
  }
}

void updateLCD()
{
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Enter Password:");
  lcd.setCursor(0, 1);
  for (int i = 0; i < input.length(); i++)
  {
    lcd.print('*');
  }
}

void checkPassword()
{
  if (input == passwordLock)
  {
    lcd.clear();
    lcd.print("Access Granted");
    unlockDoor();
    sendNotification("Door Unlocked", "Someone has entered the home.");
    delay(5000);
    lockDoor();
    lcd.clear();
    lcd.print("Door Locked");
    delay(1000);
    // Reset failed attempts on successful entry
    Firebase.setInt(fbdo, "/failedAttempts", 0);
  }
  else
  {
    lcd.clear();
    lcd.print("Access Denied");
    delay(2000);
    // Increment failed attempts
    incrementFailedAttempts();
  }
  input = "";
  updateLCD();
}

void incrementFailedAttempts()
{
  if (Firebase.ready())
  {
    FirebaseJson json;
    json.add("timestamp", Firebase.getCurrentTime());
    json.add("attempts", 1);

    if (Firebase.pushAsync(fbdo, "/failedAttempts", json))
    {
      Serial.println("Failed attempt recorded successfully");
    }
    else
    {
      Serial.println("Failed to record failed attempt");
      Serial.println("REASON: " + fbdo.errorReason());
    }
  }
}

void unlockDoor()
{
  sg90.write(unlockedPosition);
  lockState = true;
  lcd.clear();
  lcd.print("Door Unlocked");
  updateFirebaseLockState(true);
}

void lockDoor()
{
  sg90.write(lockedPosition);
  lockState = false;
  lcd.clear();
  lcd.print("Door Locked");
  updateFirebaseLockState(false);
}

void checkMotion()
{
  bool currentMotionState = digitalRead(PIR_PIN) == HIGH;
  digitalWrite(ONBOARD_LED_PIN, currentMotionState ? HIGH : LOW);
  if (currentMotionState != motionDetected)
  {
    motionDetected = currentMotionState;
    updateFirebaseMotionState(motionDetected);
    if (motionDetected)
    {
      sendNotification("Motion Detected", "Movement detected near the smart lock.");
    }
  }
}

void updateFirebaseLockState(bool isUnlocked)
{
  if (Firebase.setBool(fbdo, "/lockState", isUnlocked))
  {
    Serial.println("Firebase lock state updated successfully");
  }
  else
  {
    Serial.println("Failed to update Firebase lock state");
    Serial.println("REASON: " + fbdo.errorReason());
  }
}

void updateFirebaseMotionState(bool detected)
{
  if (Firebase.setBoolAsync(fbdo, "/motionDetected", detected))
  {
    Serial.println("Firebase motion state update queued successfully");
  }
  else
  {
    Serial.println("Failed to queue Firebase motion state update");
    Serial.println("REASON: " + fbdo.errorReason());
  }
}

void updateFirebaseStates()
{
  FirebaseJson json;
  json.set("lockState", lockState);
  json.set("remoteLedState", remoteLedState);
  json.set("motionDetected", motionDetected);

  if (Firebase.updateNodeAsync(fbdo, "/", json))
  {
    Serial.println("Firebase states update queued successfully");
  }
  else
  {
    Serial.println("Failed to queue Firebase states update");
    Serial.println("REASON: " + fbdo.errorReason());
  }
}

void handleFirebaseData()
{
  if (Firebase.getBool(fbdo, "/lockState"))
  {
    bool remoteLocKState = fbdo.boolData();
    if (remoteLocKState != lockState)
    {
      if (remoteLocKState)
      {
        unlockDoor();
        sendNotification("Door Unlocked", "Door unlocked remotely.");
      }
      else
      {
        lockDoor();
        sendNotification("Door Locked", "Door locked remotely.");
      }
    }
  }

  if (Firebase.getBool(fbdo, "/remoteLedState"))
  {
    bool currentRemoteLEDState = fbdo.boolData();
    if (currentRemoteLEDState != remoteLedState)
    {
      remoteLedState = currentRemoteLEDState;
      digitalWrite(REMOTE_LED_PIN, remoteLedState ? HIGH : LOW);
      Serial.println(remoteLedState ? "Remote LED ON" : "Remote LED OFF");
    }
  }

  if (Firebase.getString(fbdo, "/newPassword"))
  {
    String newPassword = fbdo.stringData();
    if (newPassword != "" && newPassword != passwordLock)
    {
      passwordLock = newPassword;
      preferences.putString("password", passwordLock);
      Firebase.setString(fbdo, "/newPassword", "");
      sendNotification("Password Changed", "The smart lock password has been updated.");
    }
  }
}

void sendNotification(const char *title, const char *body)
{
  FirebaseJson json;
  json.add("title", title);
  json.add("body", body);

  if (Firebase.pushAsync(fbdo, "/notifications", json))
  {
    Serial.println("Notification queued successfully");
  }
  else
  {
    Serial.println("Failed to queue notification");
    Serial.println("REASON: " + fbdo.errorReason());
  }
}

void checkWiFiConnection()
{
  if (WiFi.status() != WL_CONNECTED)
  {
    Serial.println("WiFi connection lost. Reconnecting...");
    WiFi.disconnect();
    WiFi.begin(ssid, password);
  }
}