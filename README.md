# 📈 AssetWallet – Aplikacja do zarządzania portfelem kryptowalut

**AssetWallet** to mobilna aplikacja do zarządzania portfelem inwestycyjnym w kryptowaluty. Umożliwia śledzenie wartości aktywów, analizę zmian cen oraz generowanie powiadomień o istotnych zmianach wartości portfela.

---

## ✨ Kluczowe funkcjonalności
- 🔐 **Rejestracja i logowanie użytkowników** (Firebase Authentication)
- 📊 **Monitorowanie wartości portfela** w czasie rzeczywistym (API CoinGecko)
- 🔔 **Powiadomienia lokalne push** o zmianach wartości portfela przekraczających określony próg (domyślnie ±5%)
- 📈 **Wizualizacja danych** – wykres przedstawiający historię wartości portfela
- 📉 **Analiza historyczna** – pobieranie historycznych danych z API CoinGecko
- 💾 **Przechowywanie danych** – synchronizacja i zapis inwestycji w Firebase Firestore

---

## 📷 Zrzuty ekranu
<p align="center">
  <img src="screenshots/screen1.png" width="250">
  <img src="screenshots/screen2.png" width="250">
  <img src="screenshots/screen3.png" width="250">
</p>

---

## 🛠 Technologie
Projekt został zbudowany przy użyciu następujących technologii:

| Warstwa        | Technologia            |
|---------------|-----------------------|
| **Frontend**  | Flutter                |
| **Backend**   | Django  |
| **Baza danych** | Firebase Firestore  |
| **Autoryzacja** | Firebase Authentication |
| **Dane rynkowe** | CoinGecko API |

---

## 🚀 Uruchamianie projektu

### **1️⃣ Klonowanie repozytorium**
```sh
git clone https://github.com/Cz-Oscar/AssetWallet.git
cd AssetWallet
```
### 2️⃣ Instalacja zależności
📱 Flutter
```sh
flutter pub get
```
🖥 Backend Django
```
cd crypto_backend
pip install -r requirements.txt
```
4️⃣ Uruchomienie aplikacji
📱 Flutter
```
flutter run
```
🖥 Backend Django
```
cd crypto_backend
python3 manage.py runserver
```
Autor
👤 **Oscar Czempiel**  
- [LinkedIn](https://www.linkedin.com/in/oscar-czempiel/)
- [GitHub](https://github.com/Cz-Oscar)
