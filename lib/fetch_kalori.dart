import 'package:supabase_flutter/supabase_flutter.dart';

class Kalori_Repository{
  Kalori_Repository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<List<double>> Kalori_Mingguan({required String userID}) async{

    final List<double> result = List.generate(7, (_) => 0);

    final now = DateTime.now();
    final AwalMinggu = now.subtract(Duration(days: now.weekday));
    final AkhirMinggu = AwalMinggu.add(const Duration(days: 6));

    String toDateString(DateTime d) = d.
  }
}