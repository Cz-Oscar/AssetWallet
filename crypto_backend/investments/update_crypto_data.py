"""
Skrypt aktualizujący dane o kryptowalutach w Firestore.
"""
from apscheduler.schedulers.background import BackgroundScheduler
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import firebase_admin
import requests
import pytz  # For handling time zones
import time


# Firebase Initialization
cred = credentials.Certificate("credentials/firebase-key.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Function for updating portfolio data


def update_crypto_data():
    """
    Aktualizuje dane portfolio w Firestore.
    """

   # Calculate the time 24 hours ago
    now = datetime.now(pytz.UTC)  # Current time in UTC
    one_day_ago = now - timedelta(days=1)  # Time 24 hours ago

    # print("rozpoczeto aktualizacje danych portifolio")

    users = db.collection('users').where(
        'lastActiveAt', '>=', one_day_ago).stream()

    for user in users:
        user_id = user.id
        # print(f"Przetwarzanie użytkownika: {user_id}")

        user_data = user.to_dict()

# Calculate the new portfolio value based on market price
        new_value = calculate_portfolio_value(user_id)
        if new_value == 0:
            default_value = user_data.get(
                'default_value', 0)  # Add initialization!

            # print(
            # f"[DEBUG] Wartość portfela użytkownika {user_id} wynosi 0. Resetuję flagę.")
            db.collection('users').document(user_id).update({
                'significant_change': False,
                'current_value': 0,  # Save the current value
                # Upewnij się, że nie jest 0
                'notification_base_value': default_value if default_value > 0 else 0,
            })
            continue  # Skip further calculations

        notification_base_value = user_data.get(
            'notification_base_value', user_data.get('default_value', 0))
        default_value = user_data.get('default_value', 0)

# Skip users without investments or base value
        if notification_base_value == 0:
            notification_base_value = default_value if default_value > 0 else new_value
            if notification_base_value == 0:
                # print(
                #     f"[DEBUG] Użytkownik {user_id} nie ma żadnej wartości bazowej. Pomijam.")
                db.collection('users').document(user_id).update({
                    'current_value': new_value,  # Save the current value
                    'significant_change': False,  # Reset the flag
                })
                continue

# Calculate percentage change relative to `notification_base_value`
        change_percent = (new_value - notification_base_value) / \
            notification_base_value * 100

# Check if the change exceeded the ±5% threshold
        if abs(change_percent) >= 5:
            print(
                f"Zmiana przekroczyła próg ±5% dla użytkownika {user_id}: {change_percent:.2f}%")

            db.collection('users').document(user_id).update({
                'significant_change': True,
                'notification_base_value': new_value,  # Shift threshold to new value
                'current_value': new_value,
                'change_percent': change_percent,  # Add percentage change

                'lastActiveAt': now,  # Update activity timestamp
            })
        else:
            # Update only the current value without changing the threshold
            db.collection('users').document(user_id).update({
                'current_value': new_value,
                'significant_change': False,  # Resetuj flagę
            })

        # print(f"Zaktualizowano dane dla użytkownika {user_id}: {new_value}")


# Function to calculate portfolio value


def calculate_default_portfolio_value(user_id):
    """
    Oblicza default_value (wartość portfela wg zakupu) dla użytkownika.
    """
    try:
        user_doc = db.collection('users').document(user_id)
        investments = user_doc.collection('investments').stream()

        total_value = 0.0
        for inv in investments:
            inv_data = inv.to_dict()
            price = inv_data.get('price', 0.0)
            amount = inv_data.get('amount', 0.0)

# Calculate value (price * amount) and add to total value
            total_value += price * amount

        return total_value
    except Exception as e:
        print(f"Błąd podczas obliczania default_value dla użytkownika {
              user_id}: {e}")
        return 0.0


def calculate_portfolio_value(user_id):
    """
    Oblicza bieżącą wartość portfolio użytkownika.
    """
    investments = get_user_investments(user_id)
    if not investments:
        # print(f"[DEBUG] Brak inwestycji dla użytkownika {user_id}")
        return 0

    ids = [inv.get('id') for inv in investments if inv.get('id')]
    current_prices = get_current_prices(ids)

    # print(f"[DEBUG] Aktualne ceny: {current_prices}")

    total_value = 0
    for inv in investments:

        crypto_id = inv.get('id')
        amount = inv.get('amount', 0)

        # Debugowanie dla każdej inwestycji
        # print(f"[DEBUG] Przetwarzanie: symbol={crypto_id}, amount={amount}")

        price = current_prices.get(crypto_id, 0)
        if price == 0:
            print(f"[DEBUG] Brak ceny dla symbolu {crypto_id}")
        else:
            print(f"[DEBUG] Cena dla {crypto_id}: {price}")

        total_value += amount * price

    print(f"[DEBUG] Całkowita wartość portfolio użytkownika {
          user_id}: {total_value}")
    return total_value


# Fetch user investments


def get_user_investments(user_id):
    """
    Retrieves user investments from Firestore.
    """
    try:
        # Get a reference to the user document
        user_doc = db.collection('users').document(user_id)
        # Retrieve all documents from the 'investments' collection
        investments = user_doc.collection('investments').stream()

        # Convert each document to a dictionary and return the list of investments
        return [inv.to_dict() for inv in investments]
    except Exception as e:
        print(f"Błąd podczas pobierania inwestycji dla użytkownika {
              user_id}: {e}")
        return []


# Fetch cryptocurrency prices


def get_current_prices(ids):
    joined_ids = ','.join(ids)
    url = f"https://api.coingecko.com/api/v3/simple/price?ids={
        joined_ids}&vs_currencies=usd"
    try:
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()

        return {key: value['usd'] for key, value in data.items() if 'usd' in value}
    except Exception as e:
        print(f"Błąd podczas pobierania cen: {e}")
        return {}


# Start scheduler
scheduler = BackgroundScheduler()
scheduler.add_job(update_crypto_data, 'interval', minutes=1, max_instances=1)
scheduler.start()

# Keep process running
try:
    while True:
        time.sleep(1)
except (KeyboardInterrupt, SystemExit):
    scheduler.shutdown()
