import 'package:flutter/material.dart';
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

    // Parse dari satu row Supabase
    factory LaporanHarian.fromRow(Map<String, dynamic> row) {
        return LaporanHarian(
            totalKaloriIn:  (row['total_kalori_in']  as num?)?.toInt() ?? 0,
            totalKaloriOut: (row['total_kalori_out'] as num?)?.toInt() ?? 0,
            totalProtein:   (row['total_protein']    as num?)?.toInt() ?? 0,
            totalKarbo:     (row['total_karbo']      as num?)?.toInt() ?? 0,
            totalLemak:     (row['total_lemak']      as num?)?.toInt() ?? 0,
            tanggal: DateTime.parse(row['tanggal'] as String),
        );
    }

    factory LaporanHarian.empty() {
        return LaporanHarian(
            totalKaloriIn:  0,
            totalKaloriOut: 0,
            totalProtein:   0,
            totalKarbo:     0,
            totalLemak:     0,
            tanggal: DateTime.now(),
        );
    }
}

class Kalori_Repository{
  Kalori_Repository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

   static String toDateString(DateTime d) => d.toIso8601String().substring(0,10);

  static Future<List<double>> fetchKaloriMingguan({required String userId}) async{

    final List<double> result = List.generate(7, (_) => 0);

    final now = DateTime.now();
    final AwalMinggu = now.subtract(Duration(days: now.weekday));
    final AkhirMinggu = AwalMinggu.add(const Duration(days: 6));

    final data = await _supabase
      .from('laporan_mingguan')
      .select()
      .eq('id_user', userId)
      .gte('tanggal', toDateString(AwalMinggu))
      .lte('tanggal', toDateString(AkhirMinggu));

    for(final row in data){
      final dynamic tanggal_raw = row['tanggal'];

      DateTime? tanggal;
      if(tanggal_raw is String){
        tanggal = DateTime.tryParse(tanggal_raw);
      }else if (tanggal_raw is DateTime){
        tanggal = tanggal_raw;
      }
      
      if(tanggal == null) continue;

      final int Index = tanggal.weekday - 1;
      if(Index < 0 || Index > 6) continue;

      final num? total_kalori = row['total_kalori_in'];

      if(total_kalori != null) { 
        result[Index] = total_kalori.toDouble();
      }


    }
  return result;

  }

  static Future<LaporanHarian> fetchLaporanHariIni({required String userId}) async {
        final today = toDateString(DateTime.now());

        final data = await _supabase
            .from('laporan_harian')
            .select()
            .eq('id_user', userId)
            .eq('tanggal', today)
            .maybeSingle(); // null jika belum ada baris untuk hari ini

        if (data == null) return LaporanHarian.empty();
        return LaporanHarian.fromRow(data);
  }

  static Future<int> fetchTargetKalori({required String userId}) async {
        final data = await _supabase
            .from('users')
            .select('tdee')
            .eq('id_user', userId)
            .single();

        return (data['tdee'] as num?)?.toInt() ?? 2000;
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

        // Ambil semua log makanan hari itu — sudah ada kalori & makro per baris
        // karena input.dart sekarang sudah menghitungnya sebelum insert
        final logMakanan = await _supabase
            .from('log_makanan')
            .select('kalori_total, protein_total, karbo_total, lemak_total')
            .eq('id_user', userId)
            .eq('tanggal_catat', dateStr);

        // Ambil semua log aktivitas hari itu
        final logAktivitas = await _supabase
            .from('log_aktivitas')
            .select('kalori_total')
            .eq('id_user', userId)
            .eq('tanggal_catat', dateStr);

        // Jumlahkan semua baris
        int totalKaloriIn  = 0;
        int totalKaloriOut = 0;
        int totalProtein   = 0;
        int totalKarbo     = 0;
        int totalLemak     = 0;

        for (final row in logMakanan) {
            totalKaloriIn += (row['kalori_total']  as num?)?.toInt() ?? 0;
            totalProtein  += (row['protein_total'] as num?)?.toInt() ?? 0;
            totalKarbo    += (row['karbo_total']   as num?)?.toInt() ?? 0;
            totalLemak    += (row['lemak_total']   as num?)?.toInt() ?? 0;
        }

        for (final row in logAktivitas) {
            totalKaloriOut += (row['kalori_total'] as num?)?.toInt() ?? 0;
        }

        // Upsert — insert jika belum ada, update jika sudah ada
        await _supabase.from('laporan_harian').upsert(
            {
                'id_user'         : userId,
                'tanggal'         : dateStr,
                'total_kalori_in' : totalKaloriIn,
                'total_kalori_out': totalKaloriOut,
                'total_protein'   : totalProtein,
                'total_karbo'     : totalKarbo,
                'total_lemak'     : totalLemak,
            },
            onConflict: 'id_user, tanggal',
        );
    }

}