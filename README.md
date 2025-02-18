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

## 📸 Zrzuty ekranu

### 🔐 Ekran logowania i rejestracji
Użytkownik może zalogować się za pomocą adresu e-mail i hasła lub skorzystać z logowania Google.
<img src="screenshots/ekran_logowania.png" alt="Ekran logowania" height="750"/>

---

### 📊 Ekran inwestycji  
Użytkownik może dodać inwestycję, podając kryptowalutę, giełdę, cenę zakupu ilość oraz datę.  
<img src="screenshots/ekran_inwestycji_pelny.png" alt="Ekran inwestycji" height="750"/>


---

### 📊 Monitorowanie wartości portfela  
Widok ekranu portfela po dodaniu inwestycji – pokazuje aktualną wartość oraz historię zmian.  
<img src="screenshots/ekran_portfela_after.png" alt="Ekran portfela" height="750"/>


---

### 📈 Analiza zmian wartości portfela  
Aplikacja oferuje wykres pokazujący zmiany wartości portfela w czasie.  
<img src="screenshots/wykres_after.png" alt="Ekran wykresu" height="750"/>


---

### 🔔 Powiadomienia o zmianach wartości portfela  
Gdy wartość portfela zmienia się o więcej niż 5%, użytkownik otrzymuje powiadomienie push.  
<img src="screenshots/powiadomienie_plus.png" alt="Powiadomienie o wzroście wartości" width= "800" height="150"/>


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
🖥 Uruchomienie aktualizacji wartości portfela (wymagane do działania powiadomień):
```
cd crypto_backend/investments
python3 update_crypto_data.py
```
Autor
👤 **Oscar Czempiel**  
- [LinkedIn](https://www.linkedin.com/in/oscar-czempiel/)
- [GitHub](https://github.com/Cz-Oscar)
