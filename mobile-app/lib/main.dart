import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:slock/login_page.dart';

// Initialize FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      appId: '1:396546027123:android:dde4cb4fa28b36aa5d4406',
      messagingSenderId: '396546027123',
      projectId: 'slock-37e7b',
      apiKey: 'AIzaSyBgZFOYNnoSDrclYvFSdfzuoqilr_434do',
      databaseURL:
          'https://slock-37e7b-default-rtdb.asia-southeast1.firebasedatabase.app/',
    ),
  );

  // Initialize Firebase Analytics
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  // Initialize FCM
  await FirebaseMessaging.instance.requestPermission();

  // Get the token each time the application loads
  String? token = await FirebaseMessaging.instance.getToken();

  // Save the initial token to the database
  await saveTokenToDatabase(token!);

  // Any time the token refreshes, store this in the database too.
  FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToDatabase);

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Handle incoming messages when the app is in the foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      showLocalNotification(message.notification!);
    }
  });

  runApp(const MyApp());
}

Future<void> saveTokenToDatabase(String token) async {
  // Assume user ID is stored in a global variable userUid
  // You'll need to implement user authentication and store the user ID
  String userUid = 'example_user_id';

  // Reference to the database
  final DatabaseReference database = FirebaseDatabase.instance.ref();

  // Save the token to the database
  await database.child('users/$userUid/fcmTokens/$token').set(true);
  print('Saved token to database: $token');
}

void showLocalNotification(RemoteNotification notification) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your_channel_id',
    'your_channel_name',
    importance: Importance.max,
    priority: Priority.high,
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    notification.title,
    notification.body,
    platformChannelSpecifics,
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;

  void _handleLogin(bool loggedIn) {
    setState(() {
      _isLoggedIn = loggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Lock Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: _isLoggedIn ? ControlPage() : LoginPage(onLogin: _handleLogin),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ControlPage extends StatefulWidget {
  @override
  _ControlPageState createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  bool _remoteLedState = false;
  bool _lockState = false;
  bool _motionDetected = false;
  String _currentPassword = "";
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _database.child('remoteLedState').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _remoteLedState = event.snapshot.value as bool;
        });
      }
    });
    _database.child('lockState').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _lockState = event.snapshot.value as bool;
        });
      }
    });
    _database.child('motionDetected').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _motionDetected = event.snapshot.value as bool;
        });
      }
    });
    _database.child('currentPassword').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _currentPassword = event.snapshot.value as String;
        });
      }
    });
  }

  void _toggleRemoteLED() {
    _remoteLedState = !_remoteLedState;
    _database.child('remoteLedState').set(_remoteLedState);
  }

  void _toggleLock() {
    _lockState = !_lockState;
    _database.child('lockState').set(_lockState);
    // Remove any code here that was sending notifications when the lock state changed
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(hintText: "Enter new password"),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Change'),
              onPressed: () {
                if (_newPasswordController.text.isNotEmpty) {
                  _database
                      .child('newPassword')
                      .set(_newPasswordController.text);
                  _newPasswordController.clear();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password change requested')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Smart Lock Control')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildControlCard(
                    title: 'Remote LED',
                    state: _remoteLedState,
                    onToggle: _toggleRemoteLED,
                    icon: Icons.lightbulb,
                  ),
                  SizedBox(height: 20),
                  _buildControlCard(
                    title: 'Lock',
                    state: _lockState,
                    onToggle: _toggleLock,
                    icon: Icons.lock,
                  ),
                  SizedBox(height: 20),
                  _buildStatusCard(
                    title: 'Motion Detection',
                    state: _motionDetected,
                    icon: Icons.motion_photos_on,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _changePassword,
                    child: Text('Change Password'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlCard({
    required String title,
    required bool state,
    required VoidCallback onToggle,
    required IconData icon,
  }) {
    return SizedBox(
      width: 250, // Set a fixed width for the cards
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 48, color: state ? Colors.yellow : Colors.grey),
              SizedBox(height: 10),
              Text(title, style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text(state ? 'ON' : 'OFF',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: onToggle,
                child: Text('Toggle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required bool state,
    required IconData icon,
  }) {
    return SizedBox(
      width: 250, // Set a fixed width for the cards
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 48, color: state ? Colors.red : Colors.grey),
              SizedBox(height: 10),
              Text(title, style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text(state ? 'Detected' : 'Not Detected',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: state ? Colors.red : Colors.green)),
            ],
          ),
        ),
      ),
    );
  }
}
