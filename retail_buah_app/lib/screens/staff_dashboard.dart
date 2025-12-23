import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../main.dart'; // Import main untuk akses switcher tema
import 'home_screen.dart';
import 'login.dart';

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

  String get baseUrl => kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api';

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
          const SnackBar(content: Text('Gagal memuat riwayat')),
        );
      }
    }
  }

  void _addToCart(dynamic product) {
    final existingItemIndex = cartItems.indexWhere((item) => item['_id'] == product['_id']);

    setState(() {
      if (existingItemIndex != -1) {
        cartItems[existingItemIndex]['quantity'] = (cartItems[existingItemIndex]['quantity'] ?? 1) + 1;
      } else {
        cartItems.add({...product, 'quantity': 1});
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['nama']} ditambah ke keranjang'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _checkout() async {
    if (cartItems.isEmpty) return;

    try {
      for (var item in cartItems) {
        // 1. Buat transaksi
        await dio.post('$baseUrl/transactions', data: {
          'namaBuah': item['nama'],
          'jumlah': item['quantity'],
          'totalHarga': (item['harga'] ?? 0) * item['quantity'],
        });

        // 2. Kurangi stok
        try {
          await dio.post(
            '$baseUrl/products/${item['_id']}/reduce-stock',
            data: {'quantity': item['quantity'] ?? 1},
          );
        } catch (e) {
          print('Gagal update stok: $e');
        }
      }

      setState(() => cartItems.clear());
      _fetchTransactionHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Transaksi Berhasil!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Gagal: $e'), backgroundColor: Colors.red),
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
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Staff Dashboard',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        actions: [
          // TOMBOL SWITCH TEMA
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                color: isDark ? Colors.white : Colors.black87),
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
          _buildPenjualanTab(isDark, theme),
          _buildRiwayatTab(isDark, theme),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: const Color(0xFF00BCD4),
        unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[400],
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
          child: HomeScreen(role: 'staff', onAddToCart: _addToCart),
        ),
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: theme.dividerColor)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFFE91E63)],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Keranjang',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white,
                        child: Text('${cartItems.length}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFFE91E63))),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: cartItems.isEmpty
                      ? Center(
                          child: Icon(Icons.shopping_basket_outlined,
                              size: 40, color: isDark ? Colors.grey[700] : Colors.grey[300]))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return Card(
                              color: isDark ? Colors.grey[850] : Colors.grey[100],
                              child: ListTile(
                                dense: true,
                                title: Text(item['nama'],
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                subtitle: Text('x${item['quantity']} - Rp ${item['harga'] * item['quantity']}',
                                    style: const TextStyle(fontSize: 11)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () => _removeFromCart(index),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total'),
                          Text(
                            'Rp ${cartItems.fold<int>(0, (sum, item) => sum + ((item['harga'] as int) * (item['quantity'] as int)))}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00BCD4)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: cartItems.isEmpty ? null : _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: const Text('BAYAR', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiwayatTab(bool isDark, ThemeData theme) {
    return transactionHistory.isEmpty
        ? Center(child: Icon(Icons.history, size: 60, color: isDark ? Colors.grey[700] : Colors.grey[300]))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: transactionHistory.length,
            itemBuilder: (context, index) {
              final trx = transactionHistory[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: Color(0xFF00BCD4)),
                  title: Text(trx['namaBuah'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(trx['tanggal']?.toString().substring(0, 10) ?? ''),
                  trailing: Text('Rp ${trx['totalHarga']}',
                      style: const TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
  }
}