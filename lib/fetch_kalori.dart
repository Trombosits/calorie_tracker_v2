import 'package:supabase_flutter/supabase_flutter.dart';

class LaporanHarian {
  final int totalKaloriIn;
  final int totalKaloriOut;
  final int totalProtein;
  final int totalKarbo;
  final int totalLemak;
  final DateTime tanggal;

  const LaporanHarian({
    required this.totalKaloriIn,
    required this.totalKaloriOut,
    required this.totalProtein,
    required this.totalKarbo,
    required this.totalLemak,
    required this.tanggal,
  });

  factory LaporanHarian.fromRow(Map<String, dynamic> row) {
    return LaporanHarian(
      totalKaloriIn: (row['total_kalori_in'] as num?)?.toInt() ?? 0,
      totalKaloriOut: (row['total_kalori_out'] as num?)?.toInt() ?? 0,
      totalProtein: (row['total_protein'] as num?)?.toInt() ?? 0,
      totalKarbo: (row['total_karbo'] as num?)?.toInt() ?? 0,
      totalLemak: (row['total_lemak'] as num?)?.toInt() ?? 0,
      tanggal: DateTime.tryParse(row['tanggal']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  factory LaporanHarian.empty() {
    return LaporanHarian(
      totalKaloriIn: 0,
      totalKaloriOut: 0,
      totalProtein: 0,
      totalKarbo: 0,
      totalLemak: 0,
      tanggal: DateTime.now(),
    );
  }
}

class KaloriRepository {
  KaloriRepository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static String toDateString(DateTime date) =>
      date.toIso8601String().substring(0, 10);

  static Future<List<double>> fetchKaloriMingguan({
    required String userId,
  }) async {
    final result = List<double>.filled(7, 0);

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final data = await _supabase
        .from('laporan_harian')
        .select('tanggal, total_kalori_in')
        .eq('id_user', userId)
        .gte('tanggal', toDateString(startOfWeek))
        .lte('tanggal', toDateString(endOfWeek));

    for (final row in data) {
      final tanggal = DateTime.tryParse(row['tanggal']?.toString() ?? '');
      if (tanggal == null) continue;

      final index = tanggal.weekday - 1;
      if (index < 0 || index > 6) continue;

      result[index] = (row['total_kalori_in'] as num?)?.toDouble() ?? 0;
    }

    return result;
  }

  static Future<LaporanHarian> fetchLaporanHariIni({
    required String userId,
  }) async {
    final today = toDateString(DateTime.now());

    final data = await _supabase
        .from('laporan_harian')
        .select()
        .eq('id_user', userId)
        .eq('tanggal', today)
        .maybeSingle();

    if (data == null) return LaporanHarian.empty();
    return LaporanHarian.fromRow(data);
  }

  static Future<int> fetchTargetKalori({required String userId}) async {
    final data = await _supabase
        .from('users')
        .select('target_kalori, tdee')
        .eq('id_user', userId)
        .maybeSingle();

    if (data == null) return 2000;

    return (data['target_kalori'] as num?)?.toInt() ??
        (data['tdee'] as num?)?.toInt() ??
        2000;
  }

  static Future<List<LaporanHarian>> fetchKaloriRange({
    required String userId,
    required DateTime dari,
    required DateTime sampai,
  }) async {
    final data = await _supabase
        .from('laporan_harian')
        .select()
        .eq('id_user', userId)
        .gte('tanggal', toDateString(dari))
        .lte('tanggal', toDateString(sampai))
        .order('tanggal', ascending: true);

    return data.map((row) => LaporanHarian.fromRow(row)).toList();
  }

  static Future<void> upsertLaporanHarian({
    required String userId,
    required DateTime tanggal,
  }) async {
    final dateStr = toDateString(tanggal);

    final logMakanan = await _supabase
        .from('log_makanan')
        .select('kalori_total, protein_total, karbo_total, lemak_total')
        .eq('id_user', userId)
        .eq('tanggal_catat', dateStr);

    final logAktivitas = await _supabase
        .from('log_aktivitas')
        .select('kalori_total')
        .eq('id_user', userId)
        .eq('tanggal_catat', dateStr);

    int totalKaloriIn = 0;
    int totalKaloriOut = 0;
    int totalProtein = 0;
    int totalKarbo = 0;
    int totalLemak = 0;

    for (final row in logMakanan) {
      totalKaloriIn += (row['kalori_total'] as num?)?.toInt() ?? 0;
      totalProtein += (row['protein_total'] as num?)?.toInt() ?? 0;
      totalKarbo += (row['karbo_total'] as num?)?.toInt() ?? 0;
      totalLemak += (row['lemak_total'] as num?)?.toInt() ?? 0;
    }

    for (final row in logAktivitas) {
      totalKaloriOut += (row['kalori_total'] as num?)?.toInt() ?? 0;
    }

    await _supabase.from('laporan_harian').upsert(
      {
        'id_user': userId,
        'tanggal': dateStr,
        'total_kalori_in': totalKaloriIn,
        'total_kalori_out': totalKaloriOut,
        'total_protein': totalProtein,
        'total_karbo': totalKarbo,
        'total_lemak': totalLemak,
      },
      onConflict: 'id_user,tanggal',
    );
  }
}

// Alias agar input.dart lama tetap jalan tanpa harus langsung rename semua.
typedef Kalori_Repository = KaloriRepository;
