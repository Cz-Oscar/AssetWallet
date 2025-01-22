import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveToFirebase(
      String documentId, List<Map<String, dynamic>> data) async {
    try {
      await _firestore.collection('metadata').doc(documentId).set({
        'data': data,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      print("Dane zapisane do Firebase: $documentId");
    } catch (e) {
      print("Błąd podczas zapisywania do Firebase: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getFromFirebase(String documentId) async {
    try {
      final doc = await _firestore.collection('metadata').doc(documentId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final List<dynamic> rawData = data['data'];
        print("Pobrano dane z Firebase: $documentId");
        return rawData.cast<Map<String, dynamic>>();
      }
      print("Dokument $documentId nie istnieje w Firebase");
    } catch (e) {
      print("Błąd podczas pobierania danych z Firebase: $e");
    }
    return [];
  }

  Future<void> saveFcmToken(String userId) async {
    try {
      // Pobierz token FCM
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        // Zapisz token do Firestore w dokumencie użytkownika
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcm_token': fcmToken});
        print('Token FCM zapisany: $fcmToken');
      } else {
        print('Nie udało się uzyskać tokenu FCM.');
      }
    } catch (e) {
      print('Błąd podczas zapisywania tokenu FCM: $e');
    }
  }
}
