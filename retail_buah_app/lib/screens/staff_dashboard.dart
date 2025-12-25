import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'home_screen.dart';
import 'login.dart';
import '../widgets/theme_toggle_button.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _selectedIndex = 0;
  final dio = Dio();
  List<dynamic> cartItems = [];
  List<dynamic> transactionHistory = [];
  String searchQuery = '';

  // Tetap menggunakan URL Vercel sesuai permintaan Anda
  String get baseUrl => 'https://vercel-fix-self.vercel.app/api';
String get storageUrl => 'https://vercel-fix-self.vercel.app/uploads';
  @override
  void initState() {
    super.initState();
    _fetchTransactionHistory();
  }

  Future<void> _fetchTransactionHistory() async {
    try {
      final response = await dio.get('$baseUrl/transactions');
      setState(() => transactionHistory = response.data ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat riwayat transaksi')),
        );
      }
    }
  }

  void _addToCart(dynamic product) {
    // Pastikan menggunakan 'id' (sesuai Supabase) bukan '_id' (MongoDB)
    final productId = product['id'] ?? product['_id'];
    final existingItemIndex = cartItems.indexWhere((item) => (item['id'] ?? item['_id']) == productId);
    final quantity = product['quantity'] ?? 1;

    setState(() {
      if (existingItemIndex != -1) {
        cartItems[existingItemIndex]['quantity'] =
            (cartItems[existingItemIndex]['quantity'] ?? 1) + quantity;
      } else {
        // Simpan dengan key 'id' agar konsisten
        cartItems.add({
          ...product,
          'id': productId, 
          'quantity': quantity
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['nama']} x$quantity ditambah ke keranjang'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _checkout() async {
    if (cartItems.isEmpty) return;

    // Menampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      for (var item in cartItems) {
        final productId = item['id'] ?? item['_id'];
        final hargaProduk = item['harga'] ?? 0;
        final qty = item['quantity'] ?? 1;

        // 1. Buat transaksi (Mengirim field ganda untuk kompatibilitas backend lama & baru)
        await dio.post('$baseUrl/transactions', data: {
          'product_id': productId,      // Format SQL
          'productId': productId,       // Format Mongo (cadangan)
          'product_name': item['nama'], // Format SQL
          'namaBuah': item['nama'],     // Format Mongo (cadangan)
          'quantity': qty,              // Format SQL
          'jumlah': qty,                // Format Mongo (cadangan)
          'price': hargaProduk,
          'total_price': hargaProduk * qty,
          'totalHarga': hargaProduk * qty,
          'image_url': item['image_url'] ?? item['gambar'],
        });

        // 2. Kurangi stok produk
        await dio.put(
          '$baseUrl/products/$productId/reduce-stock',
          data: {'quantity': qty},
        );
      }

      Navigator.pop(context); // Tutup loading dialog
      setState(() => cartItems.clear());
      await _fetchTransactionHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Transaksi Berhasil! Stok telah diperbarui.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Tutup loading dialog
      print('❌ Checkout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal Checkout: Server Error (500)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeFromCart(int index) {
    setState(() => cartItems.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: () => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
        actions: const [ThemeToggleButton()],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildPenjualanTab(isDark, theme),
          _buildRiwayatTab(isDark, theme),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF00BCD4),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Penjualan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
    );
  }

  Widget _buildPenjualanTab(bool isDark, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              Expanded(
                child: HomeScreen(
                  role: 'staff',
                  onAddToCart: _addToCart,
                  searchQuery: searchQuery,
                ),
              ),
            ],
          ),
        ),
        // Sisi Kanan: Keranjang (Perbaikan Overflow)
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: theme.dividerColor)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            ),
            child: Column(
              children: [
                _buildCartHeader(),
                Expanded(
                  child: cartItems.isEmpty
                      ? const Center(child: Icon(Icons.shopping_basket_outlined, size: 40, color: Colors.grey))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) => _buildCartItem(index, isDark),
                        ),
                ),
                _buildCartFooter(theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFFE91E63)]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Keranjang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          CircleAvatar(
            radius: 10,
            backgroundColor: Colors.white,
            child: Text('${cartItems.length}', style: const TextStyle(fontSize: 10, color: Color(0xFFE91E63))),
          )
        ],
      ),
    );
  }

  Widget _buildCartItem(int index, bool isDark) {
    final item = cartItems[index];
    return Card(
      color: isDark ? Colors.grey[850] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          dense: true,
          // Menggunakan Expanded/Flexible di dalam Row ListTile untuk mencegah overflow
          title: Text(
            item['nama'] ?? '',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'x${item['quantity']} - Rp ${(item['harga'] ?? 0) * (item['quantity'] ?? 1)}',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () => _removeFromCart(index),
          ),
        ),
      ),
    );
  }

  Widget _buildCartFooter(ThemeData theme) {
    int total = cartItems.fold<int>(0, (sum, item) => sum + (((item['harga'] ?? 0) as int) * ((item['quantity'] ?? 1) as int)));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.dividerColor))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total'),
              Text('Rp $total', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00BCD4))),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: cartItems.isEmpty ? null : _checkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('BAYAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatTab(bool isDark, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _fetchTransactionHistory,
      child: transactionHistory.isEmpty
          ? const Center(child: Text("Belum ada riwayat transaksi"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: transactionHistory.length,
              itemBuilder: (context, index) {
                final trx = transactionHistory[index];
                return Card(
                  child: ListTile(
                    title: Text(trx['product_name'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Qty: ${trx['quantity']} | ${trx['tanggal']?.toString().split('T')[0] ?? ''}'),
                    trailing: Text('Rp ${trx['total_price']}', style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
    );
  }
}