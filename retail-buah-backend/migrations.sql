-- ============================================
-- MIGRATION: Update Transactions Table Schema
-- ============================================
-- Tanggal: 2025-12-24
-- Purpose: Add new columns and migrate data from old field names

-- 1. ADD NEW COLUMNS jika belum ada
ALTER TABLE transactions 
  ADD COLUMN IF NOT EXISTS product_name VARCHAR(255),
  ADD COLUMN IF NOT EXISTS quantity INT4,
  ADD COLUMN IF NOT EXISTS price INT4,
  ADD COLUMN IF NOT EXISTS total_price INT4;

-- 2. MIGRATE DATA from old columns to new columns
UPDATE transactions 
SET 
  product_name = COALESCE(nama_buah, 'Unknown'),
  quantity = COALESCE(jumlah, 0),
  total_price = COALESCE(total_harga, 0),
  price = 0
WHERE product_name IS NULL;

-- 3. VERIFY migration (preview hasil)
SELECT 
  id, 
  product_id, 
  product_name, 
  quantity, 
  price, 
  total_price, 
  tanggal 
FROM transactions 
LIMIT 5;

-- ✅ Jika sukses, semua transaksi akan muncul dengan field baru
-- ⚠️  Field lama (nama_buah, jumlah, total_harga) masih ada tapi tidak digunakan
