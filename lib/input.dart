import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

//MODEL MAKANAN
class Item_makanan {
    int id_makanan;
    String nama_makanan;
    int gram_makanan;
    DateTime tanggal;

    Item_makanan({
        required this.id_makanan,
        required this.nama_makanan,
        this.gram_makanan = 0,
        required this.tanggal,

    });
}

//MODEL AKTIVITAS
class aktivitas_item {
    int id_aktivitas;
    String nama_aktivitas;
    int menit_aktivitas;
    DateTime tanggal;

    aktivitas_item({
        required this.id_aktivitas,
        required this.nama_aktivitas,
        this.menit_aktivitas = 0,
        required this.tanggal,

    });

}

//HALAMAN UTAMA

class HalamanUtama extends StatefulWidget{
    const HalamanUtama({super.key});

    @override
    State<HalamanUtama> createState() => _HalamanUtama();
}

class _HalamanUtama extends State<HalamanUtama>{


}

