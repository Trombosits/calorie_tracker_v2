Patch ini fokus memperbaiki flow register:
- Register email biasa setelah sukses diarahkan ke MainNavigation, bukan LoginPage/DashboardPage langsung.
- Register email biasa menyimpan profile data ke auth metadata dan tabel users lewat upsert.
- Jika email confirmation ON, user diarahkan ke LoginPage untuk verifikasi dulu.
- Register Google setup tetap didukung via RegisterPage(isGoogleSetup: true).
- Google setup setelah lengkapi profil diarahkan ke MainNavigation.

Cara pasang:
1. Backup lib/main.dart dan lib/register.dart.
2. Copy main.dart dan register.dart dari ZIP ini ke C:\src\calorie_tracker_v2\lib\.
3. Jalankan flutter run -d chrome --web-port 3000.
