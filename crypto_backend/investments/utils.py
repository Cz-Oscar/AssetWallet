from firebase_admin import messaging


def send_push_notification(user_id, title, message, db):
    """
    Wysyła powiadomienie push do użytkownika za pomocą Firebase Cloud Messaging.
    """
    # Pobierz token FCM użytkownika z Firestore
    user_doc = db.collection('users').document(user_id).get()
    if not user_doc.exists:
        print(f"Użytkownik {user_id} nie istnieje.")
        return

    fcm_token = user_doc.to_dict().get('fcm_token')
    if not fcm_token:
        print(f"Brak tokenu FCM dla użytkownika {user_id}.")
        return

    # Wysyłaj powiadomienie
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=message,
        ),
        token=fcm_token,
    )
    try:
        response = messaging.send(message)
        print(f"Powiadomienie wysłane do użytkownika {user_id}: {response}")
    except Exception as e:
        print(f"Błąd podczas wysyłania powiadomienia: {e}")
