"""
Skrypt aktualizujący dane o kryptowalutach w Firestore.
"""
from apscheduler.schedulers.background import BackgroundScheduler
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import firebase_admin
import requests
import pytz  # Do obsługi stref czasowych
import time

# Licznik iteracji do testów
iteration_count = 0
max_iterations = 3  # Maksymalna liczba wywołań funkcji

# Inicjalizacja Firebase
cred = credentials.Certificate("credentials/firebase-key.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Funkcja do aktualizowania danych portfolio


def update_crypto_data():
    """
    Aktualizuje dane portfolio w Firestore.
    """
    global iteration_count
    iteration_count += 1

    # Oblicz czas sprzed 24 godzin
    now = datetime.now(pytz.UTC)  # Obecny czas w UTC
    one_day_ago = now - timedelta(days=1)  # Czas sprzed 24 godzin

    print("rozpoczeto aktualizacje danych portifolio")

    users = db.collection('users').where(
        'lastActiveAt', '>=', one_day_ago).stream()

    for user in users:
        user_id = user.id
        print(f"Przetwarzanie użytkownika: {user_id}")

        user_data = user.to_dict()

        # Oblicz nową wartość portfolio wg ceny rynkowej
        new_value = calculate_portfolio_value(user_id)
        if new_value == 0:
            print(
                f"[DEBUG] Wartość portfela użytkownika {user_id} wynosi 0. Resetuję flagę.")
            db.collection('users').document(user_id).update({
                'significant_change': False,
                'current_value': 0,  # Zapisz bieżącą wartość
                # Upewnij się, że nie jest 0
                'notification_base_value': default_value if default_value > 0 else 0,
            })
            continue  # Pomijamy dalsze obliczenia

        notification_base_value = user_data.get(
            'notification_base_value', user_data.get('default_value', 0))
        default_value = user_data.get('default_value', 0)

        # Pomijamy użytkowników bez inwestycji lub bazowej wartości
        if notification_base_value == 0:
            notification_base_value = default_value if default_value > 0 else new_value
            if notification_base_value == 0:
                print(
                    f"[DEBUG] Użytkownik {user_id} nie ma żadnej wartości bazowej. Pomijam.")
                db.collection('users').document(user_id).update({
                    'current_value': new_value,  # Zapisz bieżącą wartość
                    'significant_change': False,  # Resetuj flagę
                })
                continue

        # Oblicz zmianę procentową względem `notification_base_value`
        change_percent = (new_value - notification_base_value) / \
            notification_base_value * 100

        # Sprawdź, czy zmiana przekroczyła próg ±5%
        if abs(change_percent) >= 5:
            print(
                f"Zmiana przekroczyła próg ±5% dla użytkownika {user_id}: {change_percent:.2f}%")

            # Wyślij powiadomienie (przy użyciu istniejącej logiki w frontendzie)
            db.collection('users').document(user_id).update({
                'significant_change': True,  # Frontend obsłuży powiadomienie
                'notification_base_value': new_value,  # Przesuń próg na nową wartość
                'current_value': new_value,
                'change_percent': change_percent,  # Dodajemy zmianę procentową

                'lastActiveAt': now,  # Aktualizuj aktywność
            })
        else:
            # Zaktualizuj tylko bieżącą wartość, bez zmiany progu
            db.collection('users').document(user_id).update({
                'current_value': new_value,
                'significant_change': False,  # Resetuj flagę
            })

        print(f"Zaktualizowano dane dla użytkownika {user_id}: {new_value}")

    if iteration_count >= max_iterations:
        print(
            "[INFO] Osiągnięto maksymalną liczbę wywołań. Zatrzymywanie harmonogramu...")
        scheduler.shutdown()


# Funkcja obliczająca wartość portfolio


def calculate_default_portfolio_value(user_id):
    """
    Oblicza default_value (wartość portfela wg zakupu) dla użytkownika.
    """
    try:
        # Pobierz inwestycje użytkownika
        user_doc = db.collection('users').document(user_id)
        investments = user_doc.collection('investments').stream()

        total_value = 0.0
        for inv in investments:
            inv_data = inv.to_dict()
            price = inv_data.get('price', 0.0)
            amount = inv_data.get('amount', 0.0)

            # Oblicz wartość (price * amount) i dodaj do całkowitej wartości
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
        print(f"[DEBUG] Brak inwestycji dla użytkownika {user_id}")
        return 0

    ids = [inv.get('id') for inv in investments if inv.get('id')]
    current_prices = get_current_prices(ids)

    print(f"[DEBUG] Aktualne ceny: {current_prices}")

    total_value = 0
    for inv in investments:

        crypto_id = inv.get('id')
        amount = inv.get('amount', 0)

        # Debugowanie dla każdej inwestycji
        print(f"[DEBUG] Przetwarzanie: symbol={crypto_id}, amount={amount}")

        price = current_prices.get(crypto_id, 0)
        if price == 0:
            print(f"[DEBUG] Brak ceny dla symbolu {crypto_id}")
        else:
            print(f"[DEBUG] Cena dla {crypto_id}: {price}")

        total_value += amount * price

    print(f"[DEBUG] Całkowita wartość portfolio użytkownika {
          user_id}: {total_value}")
    return total_value


# Pobieranie inwestycji użytkownika


def get_user_investments(user_id):
    """
    Pobiera inwestycje użytkownika z Firestore.
    """
    try:
        # Pobierz referencję do dokumentu użytkownika
        user_doc = db.collection('users').document(user_id)
        # Pobierz wszystkie dokumenty z kolekcji 'investments'
        investments = user_doc.collection('investments').stream()

        # Przekształć dane każdego dokumentu na słownik i zwróć listę inwestycji
        return [inv.to_dict() for inv in investments]
    except Exception as e:
        print(f"Błąd podczas pobierania inwestycji dla użytkownika {
              user_id}: {e}")
        return []


# Pobieranie cen kryptowalut


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


# Uruchom harmonogram
scheduler = BackgroundScheduler()
scheduler.add_job(update_crypto_data, 'interval', seconds=30, max_instances=1)
scheduler.start()

# Utrzymaj proces aktywny
try:
    while True:
        time.sleep(1)
except (KeyboardInterrupt, SystemExit):
    scheduler.shutdown()
