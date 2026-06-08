import 'dart:typed_data'; // Menggunakan Uint8List agar aman di Web & Mobile
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'laporan_kalori.dart';

// Import ini harus mengarah persis ke lokasi file theme Anda
import 'theme.dart';

final supabase = Supabase.instance.client;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  /* ---------- DATA USER ---------- */
  Map<String, dynamic>? _userRow; 
  bool _isLoading = true;
  // Cache buster untuk paksa Flutter refresh gambar avatar
  String _avatarCacheBuster = '';

  // Konstanta Warna Dashboard
  static const Color _primaryColor = Color(0xFFFA6623);

  /* ---------- LIFE-CYCLE ---------- */
  @override
  void initState() {
    super.initState();
    _loadProfileData(); 
  }

  Future<void> _loadProfileData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final row = await supabase
          .from('users')
          .select('nama_lengkap, target_mode, target_kalori, tdee, avatar_url')
          .eq('id_user', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userRow = row;
          _isLoading = false;
        }); 
      }
    } catch (e) {
      debugPrint('Error Load Profile: $e'); 
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /* ---------- UPLOAD FOTO PROFIL (FIX WEB & MOBILE) ---------- */
  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (image == null) return; 

      setState(() => _isLoading = true);

      final user = supabase.auth.currentUser;
      if (user == null) return;

      final Uint8List imageBytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      
      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage.from('avatars').uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(upsert: false),
          );

      final String imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      await supabase
          .from('users')
          .update({'avatar_url': imageUrl})
          .eq('id_user', user.id);

      if (mounted) {
        final oldAvatarUrl = _userRow?['avatar_url'];
        if (oldAvatarUrl != null) {
          NetworkImage('$oldAvatarUrl?cb=$_avatarCacheBuster').evict();
        }

        final cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();

        setState(() {
          if (_userRow != null) {
            _userRow!['avatar_url'] = imageUrl;
          } else {
            _userRow = {'avatar_url': imageUrl};
          }
          _avatarCacheBuster = cacheBuster;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui foto profil: $e')),
        );
      }
    }
  }

  /* ---------- LOGOUT ---------- */
  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  /* ---------- UPDATE TARGET ---------- */
  Future<void> _updateTargetMode(String newMode) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await supabase
          .from('users')
          .select('tdee')
          .eq('id_user', user.id)
          .single();
      final tdee = (res['tdee'] as num).toDouble();
      final newTarget = switch (newMode) {
        'bulking' => (tdee + 300).round(),
        'cutting' => (tdee - 300).round(),
        _ => tdee.round(),
      };

      await supabase.from('users').update({
        'target_mode': newMode,
        'target_kalori': newTarget,
      }).eq('id_user', user.id);

      await supabase.auth.updateUser(
        UserAttributes(data: {'target_mode': newMode}),
      );

      if (mounted) {
        setState(() {
          if (_userRow != null) {
            _userRow!['target_mode'] = newMode;
            _userRow!['target_kalori'] = newTarget;
          }
        }); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Target diubah menjadi ${newMode.capitalize()}')),
        );
      }
    } catch (e) {
      debugPrint('Error Update Target: $e');
    }
  }

  /* ---------- SELECTOR WIDGET ---------- */
  Widget _targetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Target Kalori Harian',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _modeChip('maintenance', 'Maintenance')),
            const SizedBox(width: 8),
            Expanded(child: _modeChip('bulking', 'Bulking')),
            const SizedBox(width: 8),
            Expanded(child: _modeChip('cutting', 'Cutting')),
          ],
        ),
      ],
    );
  }

  Widget _modeChip(String mode, String label) {
    final currentMode = _userRow?['target_mode'] ?? 'maintenance';
    final isSelected = currentMode == mode;
    
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => _updateTargetMode(mode),
      selectedColor: _primaryColor,
      backgroundColor: Colors.grey[100],
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? _primaryColor : Colors.grey[300]!),
      ),
    );
  }

  void _EditProfileSheet(BuildContext context, String displayName, String email) {
    final nameController = TextEditingController(text: displayName);
    final emailController = TextEditingController(text: email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 16,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: const Icon(Icons.person_outline, color: _primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    if (newName.isEmpty) return;

                    final user = supabase.auth.currentUser;
                    if (user != null) {
                      try {
                        await supabase.from('users')
                            .update({'nama_lengkap': newName})
                            .eq('id_user', user.id);
                        
                        await supabase.auth.updateUser(
                          UserAttributes(data: {'nama_lengkap': newName}),
                        );

                        if (mounted) {
                          setState(() {
                            if (_userRow != null) {
                              _userRow!['nama_lengkap'] = newName;
                            }
                          });
                        }
                      } catch (e) {
                        debugPrint('Error Update Name: $e');
                      }
                    }

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profil berhasil diperbarui')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan Perubahan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: Colors.black54,
                  ),
                  child: const Text('Batal'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _EditSettingSheet(BuildContext context) {
    final List<Map<String, dynamic>> themeColors = [
      {'name': 'Oranye (Default)', 'color': _primaryColor},
      {'name': 'Ungu', 'color': Colors.deepPurple},
      {'name': 'Hijau Toska', 'color': Colors.teal},
      {'name': 'Merah Mawar', 'color': Colors.pink},
      {'name': 'Biru Samudra', 'color': Colors.blue},
      {'name': 'Hijau Zamrud', 'color': Colors.green},
    ];

    Color selectedPreviewColor = themeNotifier.seedColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.palette, color: selectedPreviewColor, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Ubah Tema Warna',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pilih warna tema yang kamu suka. Fitur ubah warna akan tersedia segera.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: themeColors.length,
                    itemBuilder: (context, index) {
                      final item = themeColors[index];
                      final Color color = item['color'];
                      final String name = item['name'];

                      final bool isSelected = selectedPreviewColor == color;

                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedPreviewColor = color;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? color : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock_clock_outlined),
                      label: const Text(
                        'Coming Soon',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showGuideSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(Icons.menu_book_outlined, color: _primaryColor, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Panduan Penggunaan',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _guideItem(
                  Icons.dashboard_outlined,
                  'Dashboard',
                  'Lihat ringkasan target kalori, kalori masuk, kalori keluar, dan makronutrien harian.',
                ),
                _guideItem(
                  Icons.restaurant_menu_outlined,
                  'Input Makanan',
                  'Cari makanan, masukkan jumlah gram, lalu tekan Hitung untuk menambahkan kalori masuk.',
                ),
                _guideItem(
                  Icons.directions_run_outlined,
                  'Input Aktivitas',
                  'Cari aktivitas, masukkan durasi menit, lalu tekan Hitung untuk mencatat kalori keluar.',
                ),
                _guideItem(
                  Icons.person_outline,
                  'Profil',
                  'Ubah foto profil, lihat target kalori, dan atur target seperti maintenance, bulking, atau cutting.',
                ),
                _guideItem(
                  Icons.calendar_today_outlined,
                  'Tanggal Input',
                  'Tanggal pada input mengikuti tanggal hari ini dan tidak bisa diedit manual agar data harian tetap konsisten.',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mengerti',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _guideItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primaryColor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* ---------- BUILD ---------- */
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: _primaryColor),
        ),
      );
    }

    final user = supabase.auth.currentUser;
    final displayName = _userRow?['nama_lengkap'] ?? user?.userMetadata?['nama_lengkap'] ?? 'Pengguna';
    final email = user?.email ?? '-';
    final avatarUrl = _userRow?['avatar_url'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
              
              // 1. Bagian Foto Profil (Avatar + Icon Edit)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage('$avatarUrl?cb=$_avatarCacheBuster'),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 80, color: Colors.white)
                        : null,
                  ),
                  
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAndUploadAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _primaryColor, 
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white, 
                            width: 4,
                          ),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 2. Bagian Label Nama & Email (Bentuk Pil)
              _infoPill(displayName, _primaryColor),
              const SizedBox(height: 8),
              _infoPill(email, const Color(0xFF8A7773)), // Warna sekunder netral dari dashboard kalori keluar
              
              const SizedBox(height: 24),
            ],
          ),

          _targetSelector(),

          const SizedBox(height: 24),

          const LaporanKaloriChart(),
          const SizedBox(height: 24),

          _menuTile(
            Icons.edit_outlined,
            'Edit Profile',
            onTap: () => _EditProfileSheet(context, displayName, email),
          ),
          _divider(),
          _menuTile(
            Icons.settings_outlined,
            'Pengaturan',
            onTap: () => _EditSettingSheet(context),
          ),
          _divider(),
          _menuTile(
            Icons.menu_book_outlined,
            'Panduan',
            onTap: _showGuideSheet,
          ),
          _divider(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ---------- HELPERS ---------- */
  Widget _menuTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black54),
      dense: true,
      onTap: onTap,
    );
  }

  Widget _divider() => Divider(height: 0, thickness: .5, color: Colors.grey[200]);

} 

Widget _infoPill(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30), 
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.2),
          blurRadius: 6,
          offset: const Offset(0, 3), 
        ),
      ],
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

/* extension agar .capitalize() tersedia */
extension StringExt on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}