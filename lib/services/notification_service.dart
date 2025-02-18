import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> checkPortfolioChange(String userId) async {
  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

  if (userDoc.exists) {
    // print("Sprawdzam significant_change dla użytkownika $userId");

    final data = userDoc.data();
    final bool significantChange = data?['significant_change'] ?? false;
    final double changePercent = (data?['change_percent'] ?? 0.0)
        .toDouble(); // get `change_percent` from Firebase

    // print("change_percent z Firebase: $changePercent");

    if (significantChange) {
      String message;

      if (changePercent > 0) {
        message =
            "Twoje portfolio wzrosło o ${changePercent.toStringAsFixed(2)}%!🥳";
      } else {
        message =
            "Twoje portfolio spadło o ${changePercent.abs().toStringAsFixed(2)}%!😞";
      }

      // print("Wiadomość powiadomienia: $message");

      // send notification
      await FlutterLocalNotificationsPlugin().show(
        0, // notification ID
        'Zmiana w portfolio!',
        message,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'channel_id', // unique canal id
            'Zmiany portfolio',
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );

      // reset 'significant_change'
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'significant_change': false});
    }
  }
}
