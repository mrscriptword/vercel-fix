import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat riwayat')),
      );
    }
  }

  void _addToCart(dynamic product) {
    final existingItem = cartItems.firstWhere(
      (item) => item['_id'] == product['_id'],
      orElse: () => null,
    );

    setState(() {
      if (existingItem != null) {
        existingItem['quantity'] = (existingItem['quantity'] ?? 1) + 1;
      } else {
        cartItems.add({...product, 'quantity': 1});
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['nama']} ditambahkan ke keranjang'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _checkout() async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang kosong!')),
      );
      return;
    }

    try {
      // Validate stock untuk semua item di keranjang
      for (var cartItem in cartItems) {
        try {
          // Fetch current product data dari server
          final productId = cartItem['_id'];
          final productName = cartItem['nama'];
          print('🔍 Validasi stok - Product ID: $productId, Nama: $productName');
          print('📡 API URL: $baseUrl/products/$productId');
          
          final response = await dio.get('$baseUrl/products/$productId');
          final currentProduct = response.data;
          final availableStock = currentProduct['stok'] ?? 0;
          final requestedQuantity = cartItem['quantity'] ?? 0;

          print('✅ Stok tersedia: $availableStock kg, diminta: $requestedQuantity kg');

          // Cek apakah stock cukup
          if (requestedQuantity > availableStock) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ Stok ${cartItem['nama']} tidak cukup!\nStok tersedia: $availableStock kg, diminta: $requestedQuantity kg',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
            return; // Stop transaksi jika ada item dengan stok kurang
          }
        } catch (e) {
          // Jika error fetching product, skip validation
          print('❌ ERROR validasi stok untuk ${cartItem['nama']}: $e');
          print('📋 CartItem data: $cartItem');
        }
      }

      // Jika semua validasi lolos, lakukan transaksi dan kurangi stok
      for (var item in cartItems) {
        // 1. Buat transaksi
        await dio.post('$baseUrl/transactions', data: {
          'namaBuah': item['nama'],
          'jumlah': item['quantity'],
          'totalHarga': (item['harga'] ?? 0) * item['quantity'],
        });

        // 2. Kurangi stok produk di database menggunakan dedicated endpoint
        try {
          final stockResponse = await dio.post(
            '$baseUrl/products/${item['_id']}/reduce-stock',
            data: {'quantity': item['quantity'] ?? 1},
          );
          print('✅ Stok ${item['nama']} dikurangi berhasil');
        } catch (e) {
          print('⚠️ Warning: Tidak bisa kurangi stok untuk ${item['nama']}: $e');
          // Transaksi tetap berhasil meski gagal update stok
        }
      }

      setState(() => cartItems.clear());
      _fetchTransactionHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Transaksi berhasil! Stok telah diperbarui.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _removeFromCart(int index) {
    setState(() => cartItems.removeAt(index));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Staff Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home/Penjualan Tab
          _buildPenjualanTab(),
          // Riwayat Tab
          _buildRiwayatTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF00BCD4),
          unselectedItemColor: Colors.grey[400],
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Penjualan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Riwayat',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPenjualanTab() {
    return Row(
      children: [
        // Left: Product List
        Expanded(
          flex: 2,
          child: HomeScreen(role: 'staff', onAddToCart: _addToCart),
        ),
        // Right: Cart
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                // Cart Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFFE91E63)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Text(
                    'Keranjang (${cartItems.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Cart Items
                Expanded(
                  child: cartItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Keranjang kosong',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            final subtotal = (item['harga'] ?? 0) * (item['quantity'] ?? 1);
                            return Card(
                              elevation: 0,
                              color: Colors.grey[50],
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['nama'] ?? 'Produk',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Rp ${item['harga']}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00BCD4).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'x${item['quantity']}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF00BCD4),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                          onPressed: () => _removeFromCart(index),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Sub: Rp $subtotal',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE91E63),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Total & Checkout
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            'Rp ${cartItems.fold<int>(0, (sum, item) => sum + (((item['harga'] ?? 0) as int) * ((item['quantity'] ?? 1) as int)))}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE91E63),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: cartItems.isEmpty ? null : _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                            disabledBackgroundColor: Colors.grey[300],
                          ),
                          child: const Text(
                            'BAYAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  Widget _buildRiwayatTab() {
    return transactionHistory.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada transaksi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: transactionHistory.length,
            itemBuilder: (context, index) {
              final transaction = transactionHistory[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 1,
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00BCD4), Color(0xFFE91E63)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    transaction['namaBuah'] ?? 'Transaksi',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    transaction['tanggal']?.toString().substring(0, 10) ?? '',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rp ${transaction['totalHarga']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE91E63),
                        ),
                      ),
                      Text(
                        'x${transaction['jumlah']}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}