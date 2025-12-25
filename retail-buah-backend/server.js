require('dotenv').config();
const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();

// 1. MIDDLEWARE
app.use(cors());
app.use(express.json());

// 2. KONFIGURASI SUPABASE
const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY
);

// 3. PESAN KONEKSI DATABASE (LOG KETIKA TERHUBUNG)
async function checkSupabaseConnection() {
    try {
        const { data, error } = await supabase.from('products').select('count', { count: 'exact', head: true });
        
        if (error) throw error;

        console.log('================================================');
        console.log('✅ KONEKSI SUPABASE BERHASIL!');
        console.log(`📡 URL: ${process.env.SUPABASE_URL}`);
        console.log('📦 Database Status: Tabel "products" terdeteksi.');
        console.log('🚀 SISTEM RETAIL BUAH SIAP DIGUNAKAN');
        console.log('================================================');
    } catch (err) {
        console.error('================================================');
        console.error('❌ GAGAL MENGHUBUNGKAN KE SUPABASE!');
        console.error(`Pesan Error: ${err.message}`);
        console.error('Pastikan URL dan SERVICE_KEY di .env sudah benar.');
        console.error('================================================');
    }
}

checkSupabaseConnection();

const JWT_SECRET = process.env.JWT_SECRET || 'rahasia_toko_buah';

// ================= ROUTES =================

// --- AUTH ---
app.post('/api/register', async (req, res) => {
    try {
        const { username, password, role } = req.body;
        const hashedPassword = await bcrypt.hash(password, 10);
        const { error } = await supabase.from('users').insert([
            { email: username, password: hashedPassword, role: role || 'staff' }
        ]);
        if (error) throw error;
        res.status(201).json({ message: "User berhasil dibuat" });
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

app.post('/api/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        const { data: users, error } = await supabase.from('users').select('*').eq('email', username);
        if (error || !users.length) return res.status(401).json({ message: "User tidak ditemukan" });
        
        const user = users[0];
        const match = await bcrypt.compare(password, user.password);
        if (!match) return res.status(401).json({ message: "Password salah" });
        
        const token = jwt.sign({ id: user.id, role: user.role }, JWT_SECRET);
        res.json({ token, role: user.role, username: user.email });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// --- PRODUCTS ---
app.get('/api/products', async (req, res) => {
    const { data, error } = await supabase.from('products').select('*').order('created_at', { ascending: false });
    if (error) return res.status(500).json(error);
    res.json(data);
});

// --- TRANSACTIONS ---

// 1. GET ALL TRANSACTIONS (Riwayat)
app.get('/api/transactions', async (req, res) => {
    try {
        const { data, error } = await supabase.from('transactions').select('*').order('tanggal', { ascending: false });
        if (error) throw error;
        res.json(data);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// 2. POST TRANSACTION (Simpan Penjualan)
app.post('/api/transactions', async (req, res) => {
    try {
        const { product_id, productId, product_name, namaBuah, quantity, jumlah, price, harga, total_price, totalHarga, image_url } = req.body;
        
        const insertData = {
            product_id: product_id || productId,
            product_name: product_name || namaBuah,
            quantity: quantity || jumlah,
            price: price || harga,
            total_price: total_price || totalHarga,
            image_url: image_url,
            tanggal: new Date().toISOString()
        };

        const { data, error } = await supabase.from('transactions').insert([insertData]).select();
        if (error) throw error;
        
        console.log(`🛒 Transaksi Baru: ${insertData.product_name} x ${insertData.quantity}`);
        res.status(201).json(data[0]);
    } catch (err) {
        console.error('❌ Gagal Simpan Transaksi:', err.message);
        res.status(500).json({ message: err.message });
    }
});

// --- REDUCE STOCK ---
app.put('/api/products/:id/reduce-stock', async (req, res) => {
    try {
        const { quantity } = req.body;
        const { data: prod } = await supabase.from('products').select('stok').eq('id', req.params.id).single();
        if (!prod) throw new Error("Produk tidak ditemukan");

        const newStok = Math.max(0, prod.stok - quantity);
        const { data, error } = await supabase.from('products').update({ stok: newStok }).eq('id', req.params.id).select();
        
        if (error) throw error;
        console.log(`📉 Stok Diperbarui: Sisa stok ${newStok}`);
        res.json(data[0]);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// 6. RUN SERVER
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`
    ================================================
    🌐 SERVER LOKAL AKTIF!
    📍 Alamat: http://localhost:${PORT}
    🛠️  Mode: Pengembangan (Retail Buah v2)
    ================================================
    `);
});

module.exports = app;