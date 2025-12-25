const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();

// 1. MIDDLEWARE SANGAT PENTING UNTUK APK
// Konfigurasi CORS yang lebih spesifik agar APK tidak diblokir oleh Vercel
app.use(cors({
  origin: '*', // Mengizinkan semua akses (penting untuk Android/iOS)
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  credentials: true
}));

app.use(express.json());

// 2. KONFIGURASI SUPABASE
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// Test koneksi saat startup
supabase.from('users').select('id').limit(1)
  .then(() => console.log('✅ Terhubung ke Supabase'))
  .catch((err) => console.error('❌ Gagal Koneksi Supabase:', err.message));

const JWT_SECRET = process.env.JWT_SECRET || 'rahasia_toko_buah_super_aman';

// ================= ROUTES =================

// Root route untuk cek status server
app.get('/', (req, res) => {
  res.json({ status: "Server is running!", environment: process.env.NODE_ENV || "development" });
});

// --- AUTH ---
app.post('/api/register', async (req, res) => {
  try {
    const { username, password, role } = req.body;
    if (!username || !password) return res.status(400).json({ message: "Username dan password wajib diisi" });

    const hashedPassword = await bcrypt.hash(password, 10);
    
    const { error } = await supabase
      .from('users')
      .insert([{ username, password: hashedPassword, role: role || 'staff' }]);
    
    if (error) throw error;
    res.status(201).json({ message: "User berhasil dibuat" });
  } catch (err) {
    res.status(400).json({ message: "Username sudah digunakan atau error database" });
  }
});

app.post('/api/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    const { data: users, error } = await supabase
      .from('users')
      .select('*')
      .eq('username', username);
    
    if (error || !users || users.length === 0) {
      return res.status(401).json({ message: "Username tidak ditemukan" });
    }
    
    const user = users[0];
    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(401).json({ message: "Password salah" });
    }
    
    const token = jwt.sign({ userId: user.id, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, role: user.role, userId: user.id, username: user.username });
  } catch (err) {
    res.status(500).json({ message: "Internal server error" });
  }
});

// --- PRODUCTS ---
app.get('/api/products', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.post('/api/products', async (req, res) => {
  try {
    const { nama, harga, stok, image_url } = req.body;
    const { data, error } = await supabase
      .from('products')
      .insert([{ nama, harga: parseInt(harga), stok: parseInt(stok), image_url }])
      .select();
    
    if (error) throw error;
    res.status(201).json(data[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// --- TRANSACTIONS ---
app.post('/api/transactions', async (req, res) => {
  try {
    const { product_id, product_name, quantity, price, total_price, image_url } = req.body;
    
    const insertData = { 
      product_id,
      product_name,
      quantity,
      price: price || 0,
      total_price,
      tanggal: new Date().toISOString(),
      image_url: image_url || null
    };
    
    const { data, error } = await supabase
      .from('transactions')
      .insert([insertData])
      .select();
    
    if (error) throw error;
    res.status(201).json(data[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// --- STOCK MANAGEMENT ---
app.put('/api/products/:id/reduce-stock', async (req, res) => {
  try {
    const { quantity } = req.body;
    const productId = req.params.id;
    
    const { data: product, error: fetchErr } = await supabase
      .from('products')
      .select('stok')
      .eq('id', productId)
      .single();
    
    if (fetchErr || !product) throw new Error("Produk tidak ditemukan");
    
    const newStok = Math.max(0, product.stok - quantity);
    
    const { data, error } = await supabase
      .from('products')
      .update({ stok: newStok, updated_at: new Date().toISOString() })
      .eq('id', productId)
      .select();
    
    if (error) throw error;
    res.json(data[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// 6. JALANKAN SERVER
const PORT = process.env.PORT || 3000;

// Vercel mendeteksi 'module.exports' sebagai serverless function
if (process.env.NODE_ENV !== 'production') {
  app.listen(PORT, () => console.log(`🚀 Server jalan di http://localhost:${PORT}`));
}

module.exports = app;
