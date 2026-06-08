Patch debug utama:
1. main.dart sekarang pakai AuthGate + MainNavigation, bukan langsung DashboardPage kosong.
2. AuthGate memastikan row users ada untuk user Google/email.
3. navbar.dart sekarang benar-benar memakai DashboardPage, HalamanUtama (input.dart), dan ProfilePage.
4. dashboard.dart sekarang fetch data dari users + laporan_harian Supabase, bukan hardcoded nol.
5. fetch_kalori.dart diperbaiki agar target pakai target_kalori dan laporan mingguan pakai laporan_harian.
6. auth_service.dart menghapus warning accessToken null check yang tidak perlu.
7. register.dart menghapus import main.dart yang tidak dipakai.

Cara pakai:
- Replace file di lib/ dengan file patch ini.
- Jalankan flutter analyze.
- Jalankan flutter run -d chrome --web-port 3000.
