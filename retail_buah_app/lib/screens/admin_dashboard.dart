import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Admin Dashboard',
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
          // Home Tab
          HomeScreen(role: 'admin'),
          // Analytics Tab
          const _AnalyticsTab(),
          // Products Tab
          _ProductsTab(baseUrl: baseUrl, dio: dio),
          // Staff Tab
          _StaffTab(baseUrl: baseUrl, dio: dio),
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
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF00BCD4),
          unselectedItemColor: Colors.grey[400],
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Analitik',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory),
              label: 'Produk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Staff',
            ),
          ],
        ),
      ),
    );
  }
}

// Analytics Tab
class _AnalyticsTab extends StatefulWidget {
  const _AnalyticsTab();

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  final dio = Dio();
  List<dynamic> transactions = [];
  int totalPenjualan = 0;
  int totalTransaksi = 0;
  bool _isLoading = true;

  String get baseUrl => kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api';

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      final response = await dio.get('$baseUrl/transactions');
      setState(() {
        transactions = response.data ?? [];
        totalTransaksi = transactions.length;
        totalPenjualan = transactions.fold<int>(0, (sum, item) => sum + ((item['totalHarga'] ?? 0) as int));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
            ),
          )
        : RefreshIndicator(
            onRefresh: _fetchAnalytics,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Penjualan',
                        'Rp $totalPenjualan',
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Transaksi',
                        '$totalTransaksi',
                        Icons.receipt,
                        const Color(0xFFE91E63),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Transactions List
                Text(
                  'Riwayat Transaksi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                transactions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Belum ada transaksi',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
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
                                child: const Icon(Icons.receipt, color: Colors.white),
                              ),
                              title: Text(
                                transaction['namaBuah'] ?? 'Transaksi',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                transaction['tanggal']?.toString().substring(0, 10) ?? '',
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
                      ),
              ],
            ),
          );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// Products Tab
class _ProductsTab extends StatefulWidget {
  final String baseUrl;
  final Dio dio;

  const _ProductsTab({required this.baseUrl, required this.dio});

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  List<dynamic> products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await widget.dio.get('${widget.baseUrl}/products');
      setState(() {
        products = response.data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showProductDialog({dynamic product}) {
    final namaController = TextEditingController(text: product?['nama'] ?? '');
    final hargaController = TextEditingController(text: product?['harga']?.toString() ?? '');
    final stokController = TextEditingController(text: product?['stok']?.toString() ?? '');
    final isEdit = product != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama Produk'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hargaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stokController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stok'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              try {
                if (isEdit) {
                  await widget.dio.put(
                    '${widget.baseUrl}/products/${product['_id']}',
                    data: {
                      'nama': namaController.text,
                      'harga': int.parse(hargaController.text),
                      'stok': int.parse(stokController.text),
                    },
                  );
                } else {
                  await widget.dio.post(
                    '${widget.baseUrl}/products',
                    data: {
                      'nama': namaController.text,
                      'harga': int.parse(hargaController.text),
                      'stok': int.parse(stokController.text),
                    },
                  );
                }
                Navigator.pop(ctx);
                _fetchProducts();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Produk diperbarui' : 'Produk ditambahkan'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal menyimpan produk')),
                );
              }
            },
            child: Text(isEdit ? 'Update' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await widget.dio.delete('${widget.baseUrl}/products/$id');
                Navigator.pop(ctx);
                _fetchProducts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Produk dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal menghapus produk')),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00BCD4),
        onPressed: () => _showProductDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
              ),
            )
          : products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada produk',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(product['nama'] ?? 'Produk'),
                        subtitle: Text(
                          'Harga: Rp ${product['harga']} | Stok: ${product['stok']}',
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('Edit'),
                              onTap: () => _showProductDialog(product: product),
                            ),
                            PopupMenuItem(
                              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                              onTap: () => _deleteProduct(product['_id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// Staff Tab
class _StaffTab extends StatefulWidget {
  final String baseUrl;
  final Dio dio;

  const _StaffTab({required this.baseUrl, required this.dio});

  @override
  State<_StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<_StaffTab> {
  List<dynamic> staffList = [];
  bool _isLoading = true;
  String _filterRole = 'all'; // all, staff, admin

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    try {
      print('🔄 Fetching users from ${widget.baseUrl}/users');
      
      // Fetch data berdasarkan filter yang dipilih
      final url = _filterRole == 'all' 
        ? '${widget.baseUrl}/users'
        : '${widget.baseUrl}/users?role=$_filterRole';
      
      print('📡 API endpoint: $url');
      final response = await widget.dio.get(url);
      print('✅ Response: ${response.data}');
      
      setState(() {
        final fetchedUsers = response.data ?? [];
        print('👥 Fetched users: ${fetchedUsers.length}');
        
        staffList = fetchedUsers.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching users: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showStaffDialog({dynamic staff}) {
    final usernameController = TextEditingController(text: staff?['username'] ?? '');
    final passwordController = TextEditingController();
    final roleController = TextEditingController(text: staff?['role'] ?? 'staff');
    final isEdit = staff != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Staff' : 'Tambah Staff Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Masukkan username staff',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: isEdit ? 'Password Baru (kosongkan jika tidak diubah)' : 'Password',
                  hintText: 'Masukkan password',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                value: roleController.text,
                items: ['staff', 'admin'].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) roleController.text = value;
                },
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validasi
              if (usernameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Username tidak boleh kosong')),
                );
                return;
              }

              if (!isEdit && passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password harus diisi untuk staff baru')),
                );
                return;
              }

              if (!isEdit && passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password minimal 6 karakter')),
                );
                return;
              }

              try {
                if (isEdit) {
                  // Update staff
                  final updateData = {
                    'username': usernameController.text,
                    'role': roleController.text,
                  };
                  if (passwordController.text.isNotEmpty) {
                    updateData['password'] = passwordController.text;
                  }

                  await widget.dio.put(
                    '${widget.baseUrl}/users/${staff['_id']}',
                    data: updateData,
                  );

                  Navigator.pop(ctx);
                  _fetchStaff();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Staff berhasil diupdate'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // Create new staff
                  await widget.dio.post(
                    '${widget.baseUrl}/auth/register',
                    data: {
                      'username': usernameController.text,
                      'password': passwordController.text,
                      'role': roleController.text,
                    },
                  );

                  Navigator.pop(ctx);
                  _fetchStaff();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Staff baru berhasil ditambahkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(isEdit ? 'Update' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  void _deleteStaff(dynamic staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus User?'),
        content: Text('Yakin ingin menghapus user ${staff['username']}?\nTindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await widget.dio.delete('${widget.baseUrl}/users/${staff['_id']}');
                Navigator.pop(ctx);
                _fetchStaff();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ User berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Gagal menghapus: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  List<dynamic> get _filteredStaff {
    // Data sudah di-filter di database, langsung return staffList
    return staffList;
  }

  @override
  Widget build(BuildContext context) {
    final displayedUsers = _filteredStaff;
    
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00BCD4),
        onPressed: () => _showStaffDialog(),
        child: const Icon(Icons.person_add),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
              ),
            )
          : displayedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada user',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap tombol + untuk tambah user baru',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _fetchStaff();
                        },
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchStaff,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Filter Buttons
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterButton('Semua', 'all'),
                                const SizedBox(width: 8),
                                _buildFilterButton('Staff', 'staff'),
                                const SizedBox(width: 8),
                                _buildFilterButton('Admin', 'admin'),
                              ],
                            ),
                          ),
                        ),
                        // Table Header
                        Container(
                          color: const Color(0xFF00BCD4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'No',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Username',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Status',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Edit',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Delete',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Table Rows
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(8),
                          itemCount: displayedUsers.length,
                          itemBuilder: (context, index) {
                            final user = displayedUsers[index];
                            final isEven = index % 2 == 0;
                            return Container(
                              color: isEven ? Colors.grey[50] : Colors.white,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            user['username'] ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: (user['role'] == 'admin')
                                                  ? Colors.orange.withOpacity(0.2)
                                                  : Colors.blue.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              (user['role'] ?? 'staff').toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: (user['role'] == 'admin')
                                                    ? Colors.orange[700]
                                                    : Colors.blue[700],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Center(
                                            child: Tooltip(
                                              message: 'Edit',
                                              child: IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                                onPressed: () => _showStaffDialog(staff: user),
                                                padding: const EdgeInsets.all(4),
                                                constraints: const BoxConstraints(),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Center(
                                            child: Tooltip(
                                              message: 'Delete',
                                              child: IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                onPressed: () => _deleteStaff(user),
                                                padding: const EdgeInsets.all(4),
                                                constraints: const BoxConstraints(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (index < displayedUsers.length - 1)
                                    Divider(
                                      height: 1,
                                      color: Colors.grey[300],
                                      indent: 12,
                                      endIndent: 12,
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildFilterButton(String label, String role) {
    final isActive = _filterRole == role;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFF00BCD4) : Colors.grey[200],
        elevation: isActive ? 4 : 0,
      ),
      onPressed: () {
        setState(() {
          _filterRole = role;
          _isLoading = true;
        });
        _fetchStaff();
      },
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
