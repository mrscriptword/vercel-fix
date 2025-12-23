import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart'; 
import 'home_screen.dart';
import 'login.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final dio = Dio();

  String get baseUrl => kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api';
  String get storageUrl => kIsWeb ? 'http://localhost:3000/uploads' : 'http://10.0.2.2:3000/uploads';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
              MyApp.of(context)?.changeTheme(newMode);
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(role: 'admin'),
          const _AnalyticsTab(),
          _ProductsTab(baseUrl: baseUrl, storageUrl: storageUrl, dio: dio),
          _StaffTab(baseUrl: baseUrl, dio: dio),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00BCD4),
        unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[400],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analitik'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Produk'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Staff'),
        ],
      ),
    );
  }
}

// ================= TAB PRODUK (CRUD + SEARCH) =================
class _ProductsTab extends StatefulWidget {
  final String baseUrl;
  final String storageUrl;
  final Dio dio;
  const _ProductsTab({required this.baseUrl, required this.storageUrl, required this.dio});

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  @override
  void initState() { super.initState(); _fetchProducts(); }

  Future<void> _fetchProducts() async {
    try {
      final res = await widget.dio.get('${widget.baseUrl}/products');
      setState(() {
        products = res.data ?? [];
        filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) { setState(() => _isLoading = false); }
  }

  void _filter(String q) {
    setState(() => filteredProducts = products.where((p) => p['nama'].toLowerCase().contains(q.toLowerCase())).toList());
  }

  void _showProductDialog({dynamic product}) {
    final nameC = TextEditingController(text: product?['nama'] ?? '');
    final priceC = TextEditingController(text: product?['harga']?.toString() ?? '');
    final stockC = TextEditingController(text: product?['stok']?.toString() ?? '');
    final isEdit = product != null;
    _imageFile = null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setST) => AlertDialog(
          title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
                    if (img != null) setST(() => _imageFile = img);
                  },
                  child: Container(
                    height: 120, width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[500]!),
                    ),
                    child: _imageFile != null
                        ? (kIsWeb ? Image.network(_imageFile!.path, fit: BoxFit.cover) : Image.file(File(_imageFile!.path), fit: BoxFit.cover))
                        : (isEdit && product['gambar'] != null && product['gambar'] != '')
                            ? Image.network('${widget.storageUrl}/${product['gambar']}', fit: BoxFit.cover)
                            : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  ),
                ),
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Nama Produk')),
                TextField(controller: priceC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga')),
                TextField(controller: stockC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                FormData data = FormData.fromMap({'nama': nameC.text, 'harga': priceC.text, 'stok': stockC.text});
                if (_imageFile != null) {
                  data.files.add(MapEntry('image', kIsWeb 
                    ? MultipartFile.fromBytes(await _imageFile!.readAsBytes(), filename: _imageFile!.name)
                    : await MultipartFile.fromFile(_imageFile!.path, filename: _imageFile!.name)));
                }
                isEdit ? await widget.dio.put('${widget.baseUrl}/products/${product['_id']}', data: data)
                       : await widget.dio.post('${widget.baseUrl}/products', data: data);
                Navigator.pop(ctx); _fetchProducts();
              },
              child: const Text('Simpan'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00BCD4),
        onPressed: () => _showProductDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: const InputDecoration(hintText: "Cari produk...", prefixIcon: Icon(Icons.search)), onChanged: _filter)),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (ctx, i) {
                final p = filteredProducts[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: Container(width: 50, height: 50, color: Colors.grey[300], child: p['gambar'] != '' ? Image.network('${widget.storageUrl}/${p['gambar']}', fit: BoxFit.cover) : const Icon(Icons.image)),
                    title: Text(p['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Rp ${p['harga']} | Stok: ${p['stok']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductDialog(product: p)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                           await widget.dio.delete('${widget.baseUrl}/products/${p['_id']}'); _fetchProducts();
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ================= TAB STAFF (VIEW + DELETE) =================
class _StaffTab extends StatefulWidget {
  final String baseUrl;
  final Dio dio;
  const _StaffTab({required this.baseUrl, required this.dio});

  @override
  State<_StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<_StaffTab> {
  List staffList = [];
  @override
  void initState() { super.initState(); _fetchStaff(); }

  Future _fetchStaff() async {
    final res = await widget.dio.get('${widget.baseUrl}/users');
    setState(() => staffList = res.data ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchStaff,
      child: staffList.isEmpty ? const Center(child: Text("Tidak ada staff")) : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: staffList.length,
        itemBuilder: (ctx, i) {
          final user = staffList[i];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF00BCD4), child: Icon(Icons.person, color: Colors.white)),
              title: Text(user['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Role: ${user['role']}"),
              trailing: IconButton(
                icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                onPressed: () async {
                  bool? confirm = await showDialog(context: context, builder: (ctx) => AlertDialog(
                    title: const Text("Hapus Akun?"),
                    content: Text("Yakin ingin menghapus ${user['username']}?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                    ],
                  ));
                  if (confirm == true) {
                    await widget.dio.delete('${widget.baseUrl}/users/${user['_id']}');
                    _fetchStaff();
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================= TAB ANALITIK =================
class _AnalyticsTab extends StatefulWidget {
  const _AnalyticsTab();
  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  final dio = Dio();
  List trans = [];
  int total = 0;
  String get baseUrl => kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api';

  @override
  void initState() { super.initState(); _fetch(); }

  Future _fetch() async {
    final res = await dio.get('$baseUrl/transactions');
    setState(() {
      trans = res.data ?? [];
      total = trans.fold(0, (s, item) => s + (item['totalHarga'] as int));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.green.withOpacity(0.1),
          child: ListTile(
            title: const Text("Total Omset"),
            subtitle: Text("Rp $total", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
            leading: const Icon(Icons.payments, color: Colors.green, size: 40),
          ),
        ),
        const SizedBox(height: 10),
        ...trans.map((t) => ListTile(title: Text(t['namaBuah']), subtitle: Text("${t['jumlah']} kg"), trailing: Text("Rp ${t['totalHarga']}"))).toList(),
      ],
    );
  }
}