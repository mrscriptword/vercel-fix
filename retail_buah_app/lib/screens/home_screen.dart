import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  final Function(dynamic)? onAddToCart;
  const HomeScreen({super.key, required this.role, this.onAddToCart});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dio = Dio();
  List<dynamic> products = [];
  bool _isLoading = true;

  String get baseUrl => kIsWeb
      ? 'http://localhost:3000/api/products'
      : 'http://10.0.2.2:3000/api/products';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await dio.get(baseUrl);
      setState(() {
        products = response.data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Gagal memuat produk');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _generateQRCode(String productId, String productName) {
    // Generate QR code data dari product ID dan nama
    // Format: PROD_[productId]_[productName]
    return 'PROD_${productId}_$productName';
  }

  Widget _buildQRCodeWidget(String qrData) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: 70,
        gapless: false,
        errorStateBuilder: (ctx, err) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              qrData.substring(0, 8),
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Retail Buah',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchProducts();
            },
          ),
        ],
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
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada produk',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchProducts,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          color: const Color(0xFF00BCD4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: Text(
                                  'No',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  'Gambar',
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
                                  'Nama Produk',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  'Stok (kg)',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  'QR Code',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (widget.role == 'staff')
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    'Aksi',
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
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            final isEven = index % 2 == 0;
                            final qrData = _generateQRCode(
                              product['_id'] ?? '',
                              product['nama'] ?? 'Produk',
                            );

                            return Container(
                              color: isEven ? Colors.grey[50] : Colors.white,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                    child: Row(
                                      children: [
                                        // No
                                        SizedBox(
                                          width: 40,
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        // Gambar
                                        SizedBox(
                                          width: 70,
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(6),
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF00BCD4), Color(0xFFE91E63)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: product['gambar'] != null && product['gambar'] != ''
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Image.network(
                                                      'http://${kIsWeb ? 'localhost' : '10.0.2.2'}:3000/uploads/${product['gambar']}',
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return const Icon(Icons.shopping_bag, color: Colors.white, size: 24);
                                                      },
                                                    ),
                                                  )
                                                : const Icon(Icons.shopping_bag, color: Colors.white, size: 24),
                                          ),
                                        ),
                                        // Nama Produk
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            product['nama'] ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Stok
                                        SizedBox(
                                          width: 70,
                                          child: Text(
                                            '${product['stok'] ?? 0}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                              color: Color(0xFF00BCD4),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        // QR Code
                                        SizedBox(
                                          width: 80,
                                          child: Tooltip(
                                            message: qrData,
                                            child: _buildQRCodeWidget(qrData),
                                          ),
                                        ),
                                        // Aksi (untuk staff)
                                        if (widget.role == 'staff')
                                          SizedBox(
                                            width: 70,
                                            child: Center(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  if (widget.onAddToCart != null) {
                                                    widget.onAddToCart!(product);
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF00BCD4),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                ),
                                                child: const Text(
                                                  'Beli',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (index < products.length - 1)
                                    Divider(
                                      height: 1,
                                      color: Colors.grey[300],
                                      indent: 8,
                                      endIndent: 8,
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
}
