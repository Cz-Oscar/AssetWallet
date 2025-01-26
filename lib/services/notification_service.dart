import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> checkPortfolioChange(String userId) async {
  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

  if (userDoc.exists) {
    print("Sprawdzam significant_change dla użytkownika $userId");

    final data = userDoc.data();
    if (data?['significant_change'] == true) {
      // Wyślij powiadomienie
      await FlutterLocalNotificationsPlugin().show(
        0, // ID powiadomienia
        'Zmiana w portfolio!',
        'Wartość Twojego portfolio zmieniła się o ponad 5%!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'channel_id', // Unikalny identyfikator kanału
            'Zmiany portfolio',
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );

      // Zresetuj flagę `significant_change`
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'significant_change': false});
    }
  }
}
