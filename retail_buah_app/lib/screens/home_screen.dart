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

  // Sesuaikan URL agar konsisten dengan file lain
  String get baseUrl => kIsWeb
      ? 'http://localhost:3000/api/products'
      : 'http://10.0.2.2:3000/api/products';
  
  String get storageUrl => kIsWeb 
      ? 'http://localhost:3000/uploads' 
      : 'http://10.0.2.2:3000/uploads';

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
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Gagal memuat produk');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _generateQRCode(String productId, String productName) {
    return 'PROD_${productId}_$productName';
  }

  Widget _buildQRCodeWidget(String qrData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4),
        // QR Code sebaiknya tetap di background putih agar mudah discan
        color: Colors.white, 
      ),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: 70,
        gapless: false,
        // Pastikan warna QR Code kontras (hitam) karena background putih
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
        errorStateBuilder: (ctx, err) {
          return const Icon(Icons.error, size: 20, color: Colors.red);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Mengikuti tema latar belakang scaffold
      backgroundColor: theme.scaffoldBackgroundColor, 
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Retail Buah',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? Colors.white : Colors.black87),
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
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada produk',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
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
                              _buildHeaderText('No', width: 40),
                              _buildHeaderText('Gambar', width: 70),
                              Expanded(child: _buildHeaderText('Nama Produk', textAlign: TextAlign.left)),
                              _buildHeaderText('Stok (kg)', width: 70),
                              _buildHeaderText('QR Code', width: 80),
                              if (widget.role == 'staff') _buildHeaderText('Aksi', width: 70),
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
                            // Row color adaptif
                            final rowColor = index % 2 == 0 
                                ? (isDark ? Colors.grey[900] : Colors.grey[50])
                                : (isDark ? theme.scaffoldBackgroundColor : Colors.white);

                            return Container(
                              color: rowColor,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                    child: Row(
                                      children: [
                                        _buildCellText('${index + 1}', width: 40),
                                        _buildImageCell(product['gambar']),
                                        Expanded(child: _buildCellText(product['nama'] ?? '-', textAlign: TextAlign.left, isBold: true)),
                                        _buildCellText('${product['stok'] ?? 0}', width: 70, color: const Color(0xFF00BCD4)),
                                        _buildQRCell(product),
                                        if (widget.role == 'staff') _buildActionCell(product),
                                      ],
                                    ),
                                  ),
                                  Divider(height: 1, color: theme.dividerColor, indent: 8, endIndent: 8),
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

  // --- Helper Widgets agar kode lebih bersih ---

  Widget _buildHeaderText(String text, {double? width, TextAlign textAlign = TextAlign.center}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        textAlign: textAlign,
      ),
    );
  }

  Widget _buildCellText(String text, {double? width, TextAlign textAlign = TextAlign.center, Color? color, bool isBold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
          color: color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
        ),
        textAlign: textAlign,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildImageCell(String? imageName) {
    return SizedBox(
      width: 70,
      child: Center(
        child: Container(
          width: 55, height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey[300],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: imageName != null && imageName.isNotEmpty
                ? Image.network(
                    '$storageUrl/$imageName',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                  )
                : const Icon(Icons.shopping_bag, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildQRCell(dynamic product) {
    final qrData = _generateQRCode(product['_id'] ?? '', product['nama'] ?? 'Produk');
    return SizedBox(
      width: 80,
      child: Tooltip(
        message: qrData,
        child: _buildQRCodeWidget(qrData),
      ),
    );
  }

  Widget _buildActionCell(dynamic product) {
    return SizedBox(
      width: 70,
      child: Center(
        child: ElevatedButton(
          onPressed: () => widget.onAddToCart?.call(product),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BCD4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Beli', style: TextStyle(fontSize: 11)),
        ),
      ),
    );
  }
}