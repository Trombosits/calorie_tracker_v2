import 'dart:developer' as dev;

// Class utility untuk mencatat waktu eksekusi suatu proses.
class Performance {
  // Menyimpan waktu mulai saat object Performance dibuat
  final int _start = DateTime.now().millisecondsSinceEpoch;

  // Nama operasi yang sedang diukur, misalnya: Login, Register, Fetch Data
  final String _operation;

  // Constructor akan langsung dijalankan saat Performance dibuat
  Performance(this._operation) {
    // Menampilkan log bahwa proses sudah dimulai
    dev.log('🚀 $_operation  |  start', name: 'Performance');
  }

  // Method untuk mencatat waktu sementara dari awal proses sampai titik tertentu
  // Parameter tag bersifat opsional, dipakai untuk memberi nama tahap proses
  void lap([String? tag]) {
    // Menghitung selisih waktu sekarang dengan waktu awal
    final ms = DateTime.now().millisecondsSinceEpoch - _start;

    // Menampilkan log waktu sementara
    dev.log(
      '⏱️  $_operation${tag != null ? ' : $tag' : ''}  |  $ms ms',
      name: 'Performance',
    );
  }

  // Method untuk mencatat total waktu eksekusi proses
  void finish() {
    // Menghitung total durasi dari awal sampai proses selesai
    final ms = DateTime.now().millisecondsSinceEpoch - _start;

    // Menampilkan log total waktu eksekusi
    dev.log('✅ $_operation  |  TOTAL  $ms ms', name: 'Performance');
  }
}
