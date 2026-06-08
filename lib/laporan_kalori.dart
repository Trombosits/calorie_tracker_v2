import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppColors {
  static const Color primary = Color(0xFF2B2D42);
  static const Color targetLineColor = Colors.pink;
  static const Color intakeLineColor = Colors.cyan;
}

class LaporanKaloriChart extends StatefulWidget {
  const LaporanKaloriChart({super.key});

  @override
  State<LaporanKaloriChart> createState() => _LaporanKaloriChartState();
}

class _LaporanKaloriChartState extends State<LaporanKaloriChart> {
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  bool _isLaporanMingguan = false; // Toggle: false = Harian, true = Mingguan
  
  double _targetKalori = 2000.0;
  List<double> _kaloriHarian = List.filled(7, 0.0); // 7 Hari (Senin - Minggu)
  List<double> _kaloriMingguan = List.filled(4, 0.0); // 4 Minggu kebelakangan

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

      // 1. AMBIL TARGET KALORI
      final userRow = await _supabase
          .from('users')
          .select('target_kalori')
          .eq('id_user', user.id)
          .maybeSingle();

      if (userRow != null && userRow['target_kalori'] != null) {
        _targetKalori = (userRow['target_kalori'] as num).toDouble();
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day); // Normalisasi jam ke 00:00
   
      // === PENGATURAN GRAFIK HARIAN (Minggu Berjalan) ===
      final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1)); 
      final endOfThisWeek = startOfThisWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      
      // === PENGATURAN GRAFIK MINGGUAN (Bulan Berjalan Kalender) ===
      final startOfMonth = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      final endOfMonth = nextMonth.subtract(const Duration(seconds: 1));

      // Ambil batas query terluas untuk mengakomodasi Harian & Mingguan
      final queryStart = startOfThisWeek.isBefore(startOfMonth) ? startOfThisWeek : startOfMonth;
      final queryEnd = endOfThisWeek.isAfter(endOfMonth) ? endOfThisWeek : endOfMonth;

      // Ambil data dari tabel laporan_harian
      final response = await _supabase
          .from('laporan_harian')
          .select('tanggal, total_kalori_in')
          .eq('id_user', user.id)
          .gte('tanggal', queryStart.toIso8601String())
          .lte('tanggal', queryEnd.toIso8601String());

      List<double> tempHarian = List.filled(7, 0.0);
      List<double> tempMingguan = List.filled(4, 0.0);
      
      // Menghitung jumlah hari di masing-masing blok minggu kalender untuk pembagi rata-rata
      List<int> daysInWeekBlock = [7, 7, 7, 7]; 
      int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
      daysInWeekBlock[3] = totalDaysInMonth - 21; // Sisa hari di minggu ke-4 (bisa 9 atau 10 hari)

      for (var item in response) {
        final date = DateTime.parse(item['tanggal']);
        final kalori = (item['total_kalori_in'] as num?)?.toDouble() ?? 0.0;

        // 1. LOGIKA GRAFIK HARIAN
        if (date.isAfter(startOfThisWeek.subtract(const Duration(seconds: 1))) && 
            date.isBefore(endOfThisWeek.add(const Duration(seconds: 1)))) {
          final dayIndex = date.weekday - 1; 
          tempHarian[dayIndex] += kalori;
        }

        // 2. LOGIKA GRAFIK MINGGUAN (Bulan Kalender Ini)
        if (date.year == now.year && date.month == now.month) {
          final dayOfMonth = date.day;
          int weekIndex = 0;

          if (dayOfMonth <= 7) {
            weekIndex = 0; // Minggu 1 (Tanggal 1 - 7)
          } else if (dayOfMonth <= 14) {
            weekIndex = 1; // Minggu 2 (Tanggal 8 - 14)
          } else if (dayOfMonth <= 21) {
            weekIndex = 2; // Minggu 3 (Tanggal 15 - 21)
          } else {
            weekIndex = 3; // Minggu 4 (Tanggal 22 - Akhir Bulan)
          }

          tempMingguan[weekIndex] += kalori;
        }
      }

      // Hitung nilai rata-rata harian untuk setiap blok minggu kalender
      for (int i = 0; i < 4; i++) {
        if (tempMingguan[i] > 0) {
          tempMingguan[i] = tempMingguan[i] / daysInWeekBlock[i]; 
        }
      }

      _kaloriHarian = tempHarian;
      _kaloriMingguan = tempMingguan;

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
      aspectRatio: 1.15,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 10),
                
                // --- TOGGLE BUTTONS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildToggleButton('Harian', !_isLaporanMingguan),
                    const SizedBox(width: 12),
                    _buildToggleButton('Mingguan', _isLaporanMingguan),
                  ],
                ),
                const SizedBox(height: 24),
                
                // --- GRAFIK ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, left: 6),
                    child: LineChart(_mainChartData()),
                  ),
                ),
                const SizedBox(height: 12),
                
                // --- LEGENDA ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegend(AppColors.intakeLineColor, "Asupan Kalori"),
                    const SizedBox(width: 16),
                    _buildLegend(AppColors.targetLineColor, "Target Harian"),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
    );
  }

  // Widget Butang Togol
  Widget _buildToggleButton(String title, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _isLaporanMingguan = title == 'Mingguan';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12, 
          height: 12, 
          decoration: BoxDecoration(
            color: color, // Pindahkan color ke dalam decoration
            shape: BoxShape.circle, // Masukkan shape ke dalam decoration
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // --- CHART CONFIGURATION ---
  LineChartData _mainChartData() {
    // Tentukan data mana yang digunakan (Harian atau Mingguan)
    List<double> currentData = _isLaporanMingguan ? _kaloriMingguan : _kaloriHarian;
    
    double maxKaloriIntake = currentData.isEmpty ? 0 : currentData.reduce(max);
    double maxY = max(maxKaloriIntake, _targetKalori) + 500;

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
            interval: 500,
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
      maxX: _isLaporanMingguan ? 3 : 6, // Jika mingguan (0-3), jika harian (0-6)
      minY: 0,
      maxY: maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.blueGrey.withValues(alpha: 0.9),
        ),
      ),
      lineBarsData: [
        _intakeLineData(currentData),
        _targetLineData(),
      ],
    );
  }

  // Garis 1: Asupan Kalori (Harian / Mingguan)
  LineChartBarData _intakeLineData(List<double> dataPoints) {
    List<FlSpot> spots = [];
    for (int i = 0; i < dataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), dataPoints[i]));
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

  // Garis 2: Target Kalori (Garis Lurus Putus-Putus)
  LineChartBarData _targetLineData() {
    return LineChartBarData(
      isCurved: false,
      color: AppColors.targetLineColor,
      barWidth: 2,
      isStrokeCapRound: false,
      dotData: const FlDotData(show: false),
      dashArray: [6, 4],
      spots: [
        FlSpot(0, _targetKalori),
        FlSpot(_isLaporanMingguan ? 3 : 6, _targetKalori),
      ],
    );
  }

  // Sumbu X (Dinamik berdasarkan Togol)
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 11);
    String text = '';
    
    if (_isLaporanMingguan) {
      // Label untuk Mingguan
      switch (value.toInt()) {
        case 0: text = 'Minggu 1'; break;
        case 1: text = 'Minggu 2'; break;
        case 2: text = 'Minggu 3'; break;
        case 3: text = 'Minggu 4'; break; // Minggu Semasa
      }
    } else {
      // Label untuk Harian
      switch (value.toInt()) {
        case 0: text = 'Senin'; break;
        case 1: text = 'Selasa'; break;
        case 2: text = 'Rabu'; break;
        case 3: text = 'Kamis'; break;
        case 4: text = 'Jumat'; break;
        case 5: text = 'Sabtu'; break;
        case 6: text = 'Minggu'; break;
      }
    }
    return SideTitleWidget(meta: meta, child: Text(text, style: style));
  }

  // Sumbu Y
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey);
    if (value % 500 != 0 || value == 0) return Container();
    
    return SideTitleWidget(
      meta: meta,
      child: Text('${value.toInt()}', style: style),
    );
  }
}