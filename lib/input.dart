
import 'package:calorie_tracker_v2/performance.dart';
import 'package:flutter/material.dart';
import 'package:calorie_tracker_v2/fetch_kalori.dart';
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

class _HalamanUtama extends State<HalamanUtama>
    with SingleTickerProviderStateMixin{

        late TabController _tabctrl;
        final _foodSearchCtrl = TextEditingController();
        final _foodItem = <Item_makanan>[];
        List<dynamic> _foodList = [];
        bool _loadingfood = false;
        final _actSearchCtrl = TextEditingController();
        final _actItem = <aktivitas_item>[];
        List<dynamic> _activityList = [];
        bool _loadingact = false;
        DateTime _selectDate = DateTime.now();

        @override
        void initState(){
            super.initState();
            _tabctrl = TabController(length: 2, vsync:this);
        }

        @override
        void dispose(){
            _tabctrl.dispose();
            _foodSearchCtrl.dispose();
            _actSearchCtrl.dispose();
            super.dispose();
        }

        Future<void> _SearchFood() async{
            final keyword = _foodSearchCtrl.text.trim();
            if (keyword.isEmpty) return;
            final perf = Performance('Search Food');
            setState(() =>
                _loadingfood = true
            );

            try{
                final res = await supabase
                .from('makanan')
                .select('id_makanan, nama_makanan')
                .ilike('nama_makanan', '%$keyword%')
                .limit(20);
            
                if(!mounted)return;

                setState(() =>
                    _foodList = res
                );
                perf.lap('API return');

                if(_foodList.isEmpty){
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tidak ada'))
                    );
                }
            }catch(e){
                perf.lap('error');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('eror: $e')));
            }finally{
                if(mounted) setState(() =>
                    _loadingfood = false
                );
                perf.finish();
            }
        }

        void _tambahMakanan(int id, String nama){
            setState(() {
              _foodItem.add(Item_makanan(id_makanan: id, nama_makanan: nama, gram_makanan: 0 ,tanggal: _selectDate));
            });
        }

        void _HapusMakanan(int index) => setState(() =>
            _foodItem.removeAt(index)
        );

        Future<void> _SearchAct() async{
            final keyword = _actSearchCtrl.text.trim();
            if (keyword.isEmpty) return;
            final perf = Performance('Search Aktivitas');
            setState(() =>
                _loadingact = true
            );

            try{
                final res = await supabase
                .from('aktivitas')
                .select('id_aktivitas, nama_aktivitas')
                .ilike('nama_aktivitas', '%$keyword%')
                .limit(20);
            
                if(!mounted)return;

                setState(() =>
                    _activityList = res
                );
                perf.lap('API return');

                if(_activityList.isEmpty){
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tidak ada'))
                    );
                }
            }catch(e){
                perf.lap('error');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('eror: $e')));
            }finally{
                if(mounted) setState(() =>
                    _loadingact = false
                );
                perf.finish();
            }
        }
        
        void _tambahAktivitas(int id, String nama){
            final perf = Performance('Add Activity');
            setState(() {
              _actItem.add(aktivitas_item(id_aktivitas: id, nama_aktivitas: nama, menit_aktivitas: 0 ,tanggal: _selectDate));
            });
            perf.lap('UI Update');
            perf.finish();
        }

        void _HapusAktivitas(int index) {
            final perf = Performance('remove Activity');
            setState(() => 
                _actItem.removeAt(index)
            );
            perf.lap('UI Update');
            perf.finish();
        }

        void _reset(){
                _foodSearchCtrl.clear();
                _actSearchCtrl.clear();
                _foodList.clear();
                _activityList.clear();
                _foodItem.clear();
                _actItem.clear();
                _selectDate = DateTime.now();
                setState(() {
                });
            }

        Future<void> _SimpanInsert() async {
            if(_foodItem.isEmpty && _actItem.isEmpty){
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tambahakan minimal 1'))
                );
                return;
            }

            for (var it in _foodItem){
                if(it.gram_makanan <= 0){
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${it.nama_makanan} belum diisi'))
                    );
                    return;
                }
            }

            for (var it in _actItem){
                if(it.menit_aktivitas <= 0){
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${it.nama_aktivitas} belum diisi'))
                    );
                    return;
                }
            }

            final perf = Performance('Save All Log');
            setState(() => _loadingfood = true);

            try{
                final UserId = supabase.auth.currentUser!.id;

                if(_foodItem.isNotEmpty){
                    final idList = _foodItem.map((it) => it.id_makanan).toList();
                    final nutrisiData = await supabase
                        .from('makanan')
                        .select('id_makanan, kalori_per100g, protein_per100g, karbo_per100g, lemak_per100g')
                        .inFilter('id_makanan', idList);

                    final nutrisiMap = {
                        for (final n in nutrisiData)
                            n['id_makanan'] as int: n
                    };

                    final foodBatch = _foodItem.map((it) {
                        final n = nutrisiMap[it.id_makanan];
                        final gram = it.gram_makanan.toDouble();

                        // Hitung proporsional berdasarkan porsi gram
                        // rumus: (gram / 100) * nilai_per_100g
                        final kaloriTotal  = n != null ? (gram / 100) * (n['kalori_per100g']  as num) : 0.0;
                        final proteinTotal = n != null ? (gram / 100) * (n['protein_per100g'] as num) : 0.0;
                        final karboTotal   = n != null ? (gram / 100) * (n['karbo_per100g']   as num) : 0.0;
                        final lemakTotal   = n != null ? (gram / 100) * (n['lemak_per100g']   as num) : 0.0;

                        return {
                        'id_user': UserId,
                        'id_makanan': it.id_makanan,
                        'porsi_gram': it.gram_makanan,
                        'tanggal_catat': it.tanggal.toIso8601String().split('T')[0],
                        'kalori_total': kaloriTotal.round(),
                        'protein_total': proteinTotal.round(),
                        'karbo_total': karboTotal.round(),
                        'lemak_total': lemakTotal.round(),
                        };
                    }
                    ).toList();     
                    await supabase.from('log_makanan').insert(foodBatch);
                    perf.lap('insert food done');
                }

                if(_actItem.isNotEmpty){
                    final idAktList = _actItem.map((it) => it.id_aktivitas).toList();
                    final aktData = await supabase
                        .from('aktivitas')
                        .select('id_aktivitas, kalori_per_menit')
                        .inFilter('id_aktivitas', idAktList);

                    final aktMap = {
                        for (final a in aktData)
                            a['id_aktivitas'] as int: a
                    };


                    final ActBatch = _actItem.map((it) {
                        final a = aktMap[it.id_aktivitas];
                        final kaloriPerMenit = a != null ? (a['kalori_per_menit'] as num).toDouble() : 0.0;

                        final kaloriTotal = (it.menit_aktivitas * kaloriPerMenit).round();

                        return {   
                        'id_user': UserId,
                        'id_aktivitas': it.id_aktivitas,
                        'durasi_menit': it.menit_aktivitas,
                        'tanggal_catat': it.tanggal.toIso8601String().split('T')[0],
                        'kalori_total'  : kaloriTotal,
                        };
                    }
                    ).toList();     
                    await supabase.from('log_aktivitas').insert(ActBatch);
                    perf.lap('insert Activity done');
                }
                final tanggalSet = <String>{
                    ..._foodItem.map((it) => it.tanggal.toIso8601String().split('T')[0]),
                    ..._actItem.map((it)  => it.tanggal.toIso8601String().split('T')[0]),
                };
                for (final tgl in tanggalSet) {
                    await Kalori_Repository.upsertLaporanHarian(
                        userId: UserId,
                        tanggal: DateTime.parse(tgl),
                    );
                }

                if(!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua log tersimpan'))
                );
                _reset();
            }catch(e){
                perf.lap('error');
                if(!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'))
                );
            }
        }

            //UI TABBAR
            @override
            Widget build(BuildContext context) {
                return GestureDetector(
                    onTap: (){
                        FocusScope.of(context).unfocus();
                        if(mounted){
                            setState(() {
                              _foodList.clear();
                              _activityList.clear();
                            });
                        }
                    },
                    child: Scaffold(
                        backgroundColor: const Color.fromARGB(255, 129, 65, 2),
                        appBar: AppBar(
                            automaticallyImplyLeading: false,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            bottom: TabBar(
                                controller: _tabctrl,
                                labelColor: const Color.fromARGB(255, 199, 164, 7),
                                indicatorColor: const Color(0xffff7c36),
                                tabs: const[
                                    Tab(text: 'Makanan', icon: Icon(Icons.restaurant)),
                                    Tab(text: 'Aktivitas', icon: Icon(Icons.directions_run)),
                                ],
                            ),
                        ),

                        body: TabBarView(
                            controller: _tabctrl,
                            children: [
                                _buildTabMakanan(),
                                _buildTabAktivitas(),
                            ],
                        ),

                        bottomNavigationBar: SafeArea(
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                        onPressed: _loadingfood ? null: _SimpanInsert,
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xffff7c36),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                            )
                                        ),
                                        child: _loadingfood
                                            ? const CircularProgressIndicator(color: Colors.white)
                                            : const Text('Save'),
                                    ),
                                ),
                            )
                        ),
                    ),
                );
            }

            //Tab MAKANAN
            Widget _buildTabMakanan(){
                return Scrollbar(
                    child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                            Row(
                                children: [
                                    Expanded(
                                        child: TextField(
                                            controller: _foodSearchCtrl,
                                            decoration: InputDecoration(
                                                labelText: 'Search Makanan',
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            textInputAction: TextInputAction.search,
                                            onSubmitted: (_) => _SearchFood(),
                                        )
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(onPressed: _SearchFood, icon: const Icon(Icons.search, size: 33,)),
                                ],
                            ),
                            const SizedBox(height: 12),

                            if(_loadingfood)
                                const Center(
                                    child: CircularProgressIndicator())
                            else if (_foodList.isNotEmpty)
                            Container(
                                height: 150,
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0XFFFFF2E3)
                                ),
                                child: Scrollbar(
                                    child: ListView.builder(
                                        itemCount: _foodList.length,
                                        itemBuilder: (_, i){
                                            final m = _foodList[i];
                                            return ListTile(
                                                leading: const Icon(Icons.add_circle_outline),
                                                title: Text(m['nama_makanan']),
                                                onTap: (){
                                                    _tambahMakanan(m['id_makanan'], m['nama_makanan']);
                                                    setState(() =>
                                                        _foodList.clear()
                                                    );
                                                },
                                            );
                                        }
                                    )
                                ),
                            ),

                            //daftar Item
                            if (_foodItem.isEmpty && _foodList.isEmpty)
                                const Center(
                                    child: Text('Makanan Kosong')
                                )
                            else
                                ListView.separated(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    itemCount: _foodItem.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (_, i){
                                        final it = _foodItem[i];
                                        return Card(
                                            margin: EdgeInsets.zero,
                                            child: Padding(
                                                padding: const EdgeInsets.all(15),
                                                child: Row(
                                                    children: [
                                                        Expanded(flex: 3, child: Text(it.nama_makanan, style: const TextStyle(fontWeight: FontWeight.w500))),
                                                        Expanded(flex: 2, child: TextField(
                                                                keyboardType: TextInputType.number,
                                                                decoration: const InputDecoration(labelText: 'Gram', border: OutlineInputBorder()),
                                                                onChanged: (v) => it.gram_makanan = int.tryParse(v) ?? 0,
                                                            ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(flex: 2,
                                                            child: InkWell(
                                                                onTap: () async{
                                                                    final pick = await showDatePicker(context: context, initialDate: it.tanggal ,
                                                                    firstDate: DateTime.now().subtract(const Duration(days: 365)), 
                                                                    lastDate: DateTime.now()
                                                                    );
                                                                    if(pick != null) setState(() =>
                                                                        it.tanggal = pick
                                                                    );
                                                                },
                                                                child: InputDecorator(
                                                                    decoration: const InputDecoration(border: OutlineInputBorder()),
                                                                    child: Text('${it.tanggal.day}/${it.tanggal.month}/${it.tanggal.year}'),
                                                                ),
                                                            ),
                                                        ),
                                                        IconButton(onPressed: () => _HapusMakanan(i), icon: const Icon(Icons.delete, color: Colors.black,)),
                                                    ],
                                                ),
                                            ),
                                        );
                                    }
                                )
                        ],
                    )
                );
            }

            //Tab Aktivitas
            Widget _buildTabAktivitas(){
                return Scrollbar(child: ListView(
                        padding: const EdgeInsets.all(15),
                        children: [
                            Row(
                                children: [
                                    Expanded(child: TextField(
                                        controller: _actSearchCtrl,
                                        decoration: InputDecoration(
                                            labelText: 'Cari Aktivitas',
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                                            ),
                                        textInputAction: TextInputAction.search,
                                        onSubmitted: (_) => _SearchAct(),
                                        ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(onPressed: _SearchAct, icon: const Icon(Icons.search, size: 33)),
                                ],
                            ),
                            const SizedBox(height: 12),

                            if(_loadingact)
                                const Center(child: CircularProgressIndicator())
                            else if (_activityList.isNotEmpty)
                                Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                        border: Border.all(color:  Colors.black),
                                        borderRadius: BorderRadius.circular(12),
                                        color: const Color(0XFFFFF2E3)
                                    ),
                                    child: Scrollbar(child: ListView.builder(
                                            itemCount: _activityList.length,
                                            itemBuilder: (_, i){
                                                final a = _activityList[i];
                                                return ListTile(
                                                    leading: const Icon(Icons.add_circle_outline),
                                                    title: Text(a['nama_aktivitas']),
                                                    onTap: (){
                                                        _tambahAktivitas(a['id_aktivitas'], a['nama_aktivitas']);
                                                        setState(() => _activityList.clear());
                                                    },
                                                );
                                            }
                                        )
                                    ),
                                ),

                                if (_actItem.isEmpty && _activityList.isEmpty)
                                    const Center(child: Text('Tidak ada Aktivitas'))
                                else
                                    ListView.separated(
                                        shrinkWrap: true,
                                        physics: const ClampingScrollPhysics(),
                                        itemCount: _actItem.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (_, i){
                                            final it = _actItem[i];
                                            return Card(
                                                margin: EdgeInsets.zero,
                                                child: Padding(padding: const EdgeInsets.all(12),
                                                    child: Row(
                                                        children: [
                                                            Expanded(flex: 3, child: Text(it.nama_aktivitas, style: const TextStyle(fontWeight: FontWeight.w500 ))),
                                                            Expanded(flex: 2, child: TextField(
                                                                    keyboardType: TextInputType.number,
                                                                    decoration: const InputDecoration(labelText: 'Menit', border: OutlineInputBorder()),
                                                                    onChanged: (v) => it.menit_aktivitas = int.tryParse(v) ?? 0,
                                                                ),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Expanded(flex: 2, 
                                                            child: InkWell(
                                                                    onTap: () async{
                                                                        final pick = await showDatePicker(context: context, initialDate: it.tanggal,
                                                                         firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now()
                                                                        );
                                                                        if(pick != null) setState(() =>
                                                                            it.tanggal = pick
                                                                        );
                                                                    },
                                                                    child: InputDecorator(
                                                                        decoration: const InputDecoration(border: OutlineInputBorder()),
                                                                        child: Text('${it.tanggal.day}/${it.tanggal.month}/${it.tanggal.year}'),
                                                                    ),
                                                                )
                                                            ),
                                                            IconButton(onPressed: () => _HapusAktivitas(i), icon: const Icon(Icons.delete, color: Colors.redAccent)),
                                                        ],
                                                    ),

                                                ),
                                            );
                                        },
                                    )
                        ],
                    )
                );
            }

        }

    



