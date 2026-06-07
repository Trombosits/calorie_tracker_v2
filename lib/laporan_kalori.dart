import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppColors {
  static const Color primary = Color(0xFF2B2D42);
  static const Color targetLineColor = Colors.pink; // Warna garis target
  static const Color intakeLineColor = Colors.cyan; // Warna garis asupan
}

class LaporanKaloriChart extends StatefulWidget {
  const LaporanKaloriChart({super.key});

  @override
  State<LaporanKaloriChart> createState() => _LaporanKaloriChartState();
}

class _LaporanKaloriChartState extends State<LaporanKaloriChart> {
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  double _targetKalori = 2000.0; // Nilai default
  List<double> _kaloriMingguan = List.filled(7, 0.0); // 7 Hari (Senin - Minggu)

  @override
  void initState() {
    super.initState();
    _fetchChartData();
  }

  Future<void> _fetchChartData() async {
    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. AMBIL TARGET KALORI DARI TABEL 'users'
      final userRow = await _supabase
          .from('users')
          .select('target_kalori')
          .eq('id_user', user.id)
          .maybeSingle();

      if (userRow != null && userRow['target_kalori'] != null) {
        _targetKalori = (userRow['target_kalori'] as num).toDouble();
      }

      // 2. AMBIL DATA KONSUMSI MINGGU INI (Senin - Minggu)
      final now = DateTime.now();
      // Cari tanggal hari Senin minggu ini
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      // Asumsi: Kamu memiliki tabel 'makanan' dengan kolom 'tanggal' dan 'kalori'
      // GANTI 'makanan' dan 'kalori' sesuai dengan nama tabel & kolom di databasemu!
      final response = await _supabase
          .from('makanan') 
          .select('tanggal, kalori')
          .eq('id_user', user.id)
          .gte('tanggal', startOfWeek.toIso8601String())
          .lte('tanggal', endOfWeek.toIso8601String());

      // Reset list mingguan
      List<double> tempKalori = List.filled(7, 0.0);

      // Kelompokkan kalori berdasarkan hari
      for (var item in response) {
        final date = DateTime.parse(item['tanggal']);
        final dayIndex = date.weekday - 1; // 0 = Senin, 6 = Minggu
        final kalori = (item['kalori'] as num).toDouble();
        
        tempKalori[dayIndex] += kalori;
      }

      _kaloriMingguan = tempKalori;

    } catch (e) {
      debugPrint('Error fetch chart data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.23,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 20),
                const Text(
                  'Laporan Kalori Mingguan',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, left: 6),
                    child: LineChart(_mainChartData()),
                  ),
                ),
                // Legenda Keterangan Warna
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegend(AppColors.intakeLineColor, "Asupan Harian"),
                    const SizedBox(width: 16),
                    _buildLegend(AppColors.targetLineColor, "Target Kalori"),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // --- CHART CONFIGURATION ---

  LineChartData _mainChartData() {
    // Cari nilai maksimal untuk sumbu Y agar grafik proporsional
    double maxKaloriIntake = _kaloriMingguan.reduce(max);
    double maxY = max(maxKaloriIntake, _targetKalori) + 500; // Tambah margin atas 500 kalori

    return LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 500, // Tampilkan angka setiap kelipatan 500
            reservedSize: 42,
            getTitlesWidget: leftTitleWidgets,
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
          left: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      ),
      minX: 0,
      maxX: 6, // 0 sampai 6 (Senin - Minggu)
      minY: 0,
      maxY: maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.blueGrey.withValues(alpha: 0.8),
        ),
      ),
      lineBarsData: [
        _intakeLineData(),
        _targetLineData(),
      ],
    );
  }

  // Garis 1: Asupan Kalori Harian
  LineChartBarData _intakeLineData() {
    List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), _kaloriMingguan[i]));
    }

    return LineChartBarData(
      isCurved: true,
      color: AppColors.intakeLineColor,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: AppColors.intakeLineColor.withValues(alpha: 0.2),
      ),
      spots: spots,
    );
  }

  // Garis 2: Target Kalori (Garis Lurus)
  LineChartBarData _targetLineData() {
    return LineChartBarData(
      isCurved: false,
      color: AppColors.targetLineColor,
      barWidth: 3,
      isStrokeCapRound: false,
      dotData: const FlDotData(show: false), // Sembunyikan titik agar jadi garis mulus
      dashArray: [5, 5], // Buat garis putus-putus
      spots: [
        FlSpot(0, _targetKalori), // Titik awal (Senin)
        FlSpot(6, _targetKalori), // Titik akhir (Minggu)
      ],
    );
  }

  // Sumbu X (Hari dalam seminggu)
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    String text;
    switch (value.toInt()) {
      case 0: text = 'Sen'; break;
      case 1: text = 'Sel'; break;
      case 2: text = 'Rab'; break;
      case 3: text = 'Kam'; break;
      case 4: text = 'Jum'; break;
      case 5: text = 'Sab'; break;
      case 6: text = 'Min'; break;
      default: text = '';
    }
    return SideTitleWidget(meta: meta, child: Text(text, style: style));
  }

  // Sumbu Y (Jumlah Kalori)
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 10);
    // Hanya tampilkan jika valuenya kelipatan 500 (biar grafik ga sumpek)
    if (value % 500 != 0 || value == 0) return Container();
    
    return SideTitleWidget(
      meta: meta,
      child: Text('${value.toInt()}', style: style),
    );
  }
}