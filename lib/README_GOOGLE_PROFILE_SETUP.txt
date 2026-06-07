Patch tujuan:
- User login Google baru tidak langsung masuk dashboard kosong.
- Kalau data profil di public.users belum lengkap, user diarahkan ke RegisterPage mode setup.
- RegisterPage mode setup hanya meminta data tubuh, tanggal lahir, gender, aktivitas, target kalori.
- Tidak meminta email/password lagi karena user sudah login lewat Google.

Cara pakai:
1. Backup file lama di lib/.
2. Copy main.dart dan register.dart dari folder ini ke C:\src\calorie_tracker_v2\lib\.
3. Pastikan RLS policy users sudah mengizinkan select/insert/update own profile.
4. Run: flutter run -d chrome --web-port 3000
