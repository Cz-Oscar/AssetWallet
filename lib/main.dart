import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_asset_wallet/pages/home_page.dart';
import 'package:flutter_asset_wallet/pages/login_or_register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_asset_wallet/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('Powiadomienie kliknięte: ${response.payload}');
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeNotifications(); // Inicjalizacja powiadomień
  SystemChrome.setEnabledSystemUIMode(SystemUiMode
      .immersiveSticky); // usuniecie paska z bateria i godzina do screenshotow

  runApp(const MyApp());
}

void startNotificationCheck(String userId) {
  print("Rozpoczęto sprawdzanie powiadomień dla użytkownika $userId");

  Timer.periodic(const Duration(seconds: 70), (timer) {
    print("Sprawdzanie powiadomień dla $userId...");

    checkPortfolioChange(userId);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthStateHandler(),
    );
  }
}

class AuthStateHandler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          startNotificationCheck(
              snapshot.data!.uid); // Uruchom ponownie funkcję
          return HomePage();
        } else {
          return const LoginOrRegisterPage();
        }
      },
    );
  }
}
