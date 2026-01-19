# Flutter aplikacija - Lijepa Allahova Imena

## Opis
Mobilna aplikacija za Android i iOS koja prikazuje dnevne notifikacije sa Allahovim imenima i poukama iz Kur'ana.

## Funkcionalnosti
- ✅ 30 poruka sa Allahovim imenima
- ✅ Dnevne notifikacije (svaki dan u 9:00)
- ✅ Prikaz trenutne dnevne poruke
- ✅ Lista svih poruka sa detaljima
- ✅ Test notifikacija dugme
- ✅ Resetovanje notifikacija
- ✅ CSV struktura: id, message, sura, ajet, imagePath

## Instalacija

### Preduslovi
- Flutter SDK (3.0.0 ili noviji)
- Android Studio (za Android)
- Xcode (za iOS, samo na macOS)

### Instalacione komande

```powershell
# Pozicioniranje u folder projekta
cd c:\Users\User\Documents\Kodiranje\LijepaAllahovaImena

# Instalacija dependencija
flutter pub get

# Pokretanje na Android emulatoru
flutter run

# Pokretanje na iOS simulatoru (macOS)
flutter run -d ios

# Build za Android APK
flutter build apk --release

# Build za iOS
flutter build ios --release
```

## Struktura projekta

```
lib/
├── main.dart                          # Glavni ulazak u aplikaciju
├── models/
│   └── message.dart                   # Model za poruke
├── services/
│   ├── csv_service.dart               # Učitavanje CSV podataka
│   └── notification_service.dart      # Upravljanje notifikacijama
└── screens/
    ├── home_screen.dart               # Glavni ekran
    └── message_detail_screen.dart     # Detalji poruke

assets/
├── messages.csv                       # CSV sa porukama
└── images/                            # Folder za slike (opciono)
```

## Korišćenje

1. **Prva instalacija**: Aplikacija automatski zakazuje notifikacije za narednih 30 dana
2. **Dnevna notifikacija**: Stiže svaki dan u 9:00 ujutro
3. **Test dugme**: Ikona zvona u gornjem desnom uglu šalje testnu notifikaciju
4. **Reset dugme**: Ikona osvežavanja resetuje ciklus notifikacija

## Dozvole

### Android
- POST_NOTIFICATIONS
- SCHEDULE_EXACT_ALARM
- RECEIVE_BOOT_COMPLETED

### iOS
- Notifikacije se automatski traže pri prvom pokretanju

## Napomene

- Za produkciju, preporučuje se dodati `timezone` paket za pravilnu timezone podršku
- Dodajte slike u `assets/images/` folder prema `imagePath` iz CSV-a
- Možete prilagoditi vreme notifikacija u `notification_service.dart` (trenutno 9:00)

## Prilagođavanje

### Promena vremena notifikacija
U fajlu `lib/services/notification_service.dart`:
```dart
final scheduledDate = DateTime(
  now.year,
  now.month,
  now.day,
  9,  // ← Promeni vreme (0-23)
  0,  // ← Promeni minute (0-59)
);
```

### Dodavanje novih poruka
Edituj `assets/messages.csv` i dodaj nove redove sa strukturom:
```
id,message,sura,ajet,imagePath
```

## Licenca
Privatni projekat
