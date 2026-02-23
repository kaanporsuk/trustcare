-- ================================================================
-- ADANA HEALTHCARE PROVIDERS SEED DATA
-- Comprehensive seed script with 60+ real and realistic providers
-- ================================================================

-- IMPORTANT SETUP INSTRUCTIONS:
-- 1. Before running this script, you need a valid user_id for reviews
-- 2. Get your user_id from: Supabase Dashboard > Auth > Users
-- 3. Replace '{YOUR_USER_ID}' below with your actual UUID
-- 4. Run with: psql $DATABASE_URL -f supabase/seed_adana_providers.sql
--    OR paste into Supabase SQL Editor

-- ================================================================
-- HOSPITALS (7 major hospitals in Adana)
-- ================================================================

INSERT INTO providers (name, specialty, clinic_name, address, city, country_code, latitude, longitude, phone, is_active, data_source, survey_type)
VALUES
-- Adana Şehir Hastanesi (City Hospital) - largest hospital in Adana
('Adana Şehir Hastanesi', 'Hospital (General)', 'Adana Şehir Hastanesi', 
 'Kuzey Çevre Yolu, Havaalanı Kavşağı, Yüreğir', 'Adana', 'TR', 
 37.0247, 35.3521, '+90 322 344 00 00', true, 'seed', 'hospital'),

-- Çukurova Üniversitesi Tıp Fakültesi
('Çukurova Üniversitesi Tıp Fakültesi', 'Hospital (General)', 'Çukurova Üniversitesi Tıp Fakültesi',
 'Balcalı, Sarıçam', 'Adana', 'TR',
 37.0122, 35.3389, '+90 322 338 60 60', true, 'seed', 'hospital'),

-- Başkent Üniversitesi Adana Hastanesi
('Başkent Üniversitesi Adana Hastanesi', 'Hospital (General)', 'Başkent Üniversitesi Adana Hastanesi',
 'Dadaloglu Mah. 39. Sok. No:6, Yüreğir', 'Adana', 'TR',
 36.9876, 35.3245, '+90 322 327 27 27', true, 'seed', 'hospital'),

-- Acıbadem Adana Hastanesi
('Acıbadem Adana Hastanesi', 'Hospital (General)', 'Acıbadem Adana Hastanesi',
 'Çınarlı Mah. Turhan Cemal Beriker Blv. No:1, Seyhan', 'Adana', 'TR',
 37.0023, 35.3112, '+90 322 428 00 00', true, 'seed', 'hospital'),

-- Medical Park Adana Hastanesi
('Medical Park Adana Hastanesi', 'Hospital (General)', 'Medical Park Adana Hastanesi',
 'Kurttepe Mah. Kennedy Cad. No:3, Seyhan', 'Adana', 'TR',
 36.9934, 35.3201, '+90 322 230 30 00', true, 'seed', 'hospital'),

-- Metro Hastanesi Adana
('Metro Hastanesi Adana', 'Hospital (General)', 'Metro Hastanesi Adana',
 'Kurtuluş Mah. Turhan Cemal Beriker Blv. No:111, Seyhan', 'Adana', 'TR',
 36.9923, 35.3145, '+90 322 459 19 19', true, 'seed', 'hospital'),

-- Ortadoğu Hastanesi
('Ortadoğu Hastanesi', 'Hospital (General)', 'Ortadoğu Hastanesi',
 'Güzelyalı Mah. Menderes Cad. No:176, Çukurova', 'Adana', 'TR',
 37.0156, 35.2987, '+90 322 425 25 25', true, 'seed', 'hospital');

-- ================================================================
-- DENTAL CLINICS (10 dental clinics)
-- ================================================================

INSERT INTO providers (name, specialty, clinic_name, address, city, country_code, latitude, longitude, phone, is_active, data_source, survey_type)
VALUES
('Adana Diş Polikliniği', 'General Dentistry', 'Adana Diş Polikliniği',
 'Ziyapaşa Bulvarı No:45, Seyhan', 'Adana', 'TR',
 36.9912, 35.3289, '+90 322 363 45 67', true, 'seed', 'dental'),

('Seyhan Dental Clinic', 'General Dentistry', 'Seyhan Dental Clinic',
 'İnönü Cad. No:89, Seyhan', 'Adana', 'TR',
 36.9889, 35.3267, '+90 322 352 78 90', true, 'seed', 'dental'),

('Dr. Dt. Mehmet Kaya - Ortodonti Merkezi', 'Orthodontics', 'Kaya Ortodonti',
 'Kuruköprü Mah. Fuzuli Cad. No:34/A, Seyhan', 'Adana', 'TR',
 36.9945, 35.3198, '+90 322 351 23 45', true, 'seed', 'dental'),

('Ağız ve Diş Sağlığı Merkezi Adana', 'General Dentistry', 'Adana Ağız Diş Sağlığı',
 'Çınarlı Mah. Atatürk Cad. No:156, Çukurova', 'Adana', 'TR',
 37.0034, 35.3089, '+90 322 233 67 89', true, 'seed', 'dental'),

('Smile Design Adana', 'Cosmetic Dentistry', 'Smile Design Adana',
 'Reşatbey Mah. Turhan Cemal Beriker Blv. No:67, Seyhan', 'Adana', 'TR',
 36.9978, 35.3167, '+90 322 457 89 12', true, 'seed', 'dental'),

('Dr. Dt. Ayşe Yılmaz Diş Kliniği', 'General Dentistry', 'Yılmaz Diş Kliniği',
 'Çakmak Mah. İnönü Cad. No:23/B, Seyhan', 'Adana', 'TR',
 36.9901, 35.3234, '+90 322 363 12 34', true, 'seed', 'dental'),

('Adana İmplant ve Protez Merkezi', 'Prosthodontics', 'İmplant Protez Merkezi',
 'Kurttepe Mah. Gazipaşa Blv. No:45, Seyhan', 'Adana', 'TR',
 36.9923, 35.3189, '+90 322 230 45 67', true, 'seed', 'dental'),

('Çocuk Diş Kliniği Adana', 'Pediatric Dentistry', 'Çocuk Diş Kliniği',
 'Güzelyalı Mah. Turgut Özal Blv. No:89, Çukurova', 'Adana', 'TR',
 37.0089, 35.3012, '+90 322 428 56 78', true, 'seed', 'dental'),

('Oral Cerrahi Merkezi - Prof. Dr. Ahmet Demir', 'Oral Surgery', 'Demir Oral Cerrahi',
 'Gülbahçe Mah. Atatürk Cad. No:178, Seyhan', 'Adana', 'TR',
 36.9967, 35.3145, '+90 322 351 90 12', true, 'seed', 'dental'),

('Endodonti Uzmanı Dt. Zeynep Kara', 'Endodontics', 'Kara Endodonti',
 'Reşatbey Mah. Kurtuluş Cad. No:34, Seyhan', 'Adana', 'TR',
 36.9934, 35.3178, '+90 322 352 34 56', true, 'seed', 'dental');

-- ================================================================
-- PHARMACIES (7 major pharmacies)
-- ================================================================

INSERT INTO providers (name, specialty, clinic_name, address, city, country_code, latitude, longitude, phone, is_active, data_source, survey_type)
VALUES
('Seyhan Eczanesi', 'Pharmacy', 'Seyhan Eczanesi',
 'Ziyapaşa Bulvarı No:123, Seyhan', 'Adana', 'TR',
 36.9923, 35.3278, '+90 322 363 78 90', true, 'seed', 'pharmacy'),

('Çukurova Eczanesi', 'Pharmacy', 'Çukurova Eczanesi',
 'Çınarlı Mah. Mustafa Kemal Paşa Blv. No:67, Çukurova', 'Adana', 'TR',
 37.0045, 35.3098, '+90 322 233 45 67', true, 'seed', 'pharmacy'),

('Merkez Eczanesi', 'Pharmacy', 'Merkez Eczanesi',
 'İnönü Cad. No:45, Seyhan', 'Adana', 'TR',
 36.9889, 35.3256, '+90 322 352 12 34', true, 'seed', 'pharmacy'),

('Yüreğir Eczanesi', 'Pharmacy', 'Yüreğir Eczanesi',
 'Cumhuriyet Mah. Atatürk Cad. No:89, Yüreğir', 'Adana', 'TR',
 36.9812, 35.3345, '+90 322 332 56 78', true, 'seed', 'pharmacy'),

('Atlas Eczanesi', 'Pharmacy', 'Atlas Eczanesi',
 'Reşatbey Mah. Gazipaşa Cad. No:34, Seyhan', 'Adana', 'TR',
 36.9945, 35.3189, '+90 322 351 67 89', true, 'seed', 'pharmacy'),

('Nöbetçi Eczanesi 7/24', 'Pharmacy', 'Nöbetçi Eczanesi',
 'Kurttepe Mah. Turhan Cemal Beriker Blv. No:156, Seyhan', 'Adana', 'TR',
 36.9967, 35.3167, '+90 322 230 90 12', true, 'seed', 'pharmacy'),

('Güzelyalı Eczanesi', 'Pharmacy', 'Güzelyalı Eczanesi',
 'Güzelyalı Mah. Turgut Özal Blv. No:234, Çukurova', 'Adana', 'TR',
 37.0112, 35.2989, '+90 322 425 34 56', true, 'seed', 'pharmacy');

-- ================================================================
-- GENERAL PRACTITIONERS / FAMILY MEDICINE (10 clinics)
-- ================================================================

INSERT INTO providers (name, specialty, clinic_name, address, city, country_code, latitude, longitude, phone, is_active, data_source, survey_type)
VALUES
('Dr. Mehmet Öztürk Aile Hekimliği', 'Family Medicine', 'Öztürk Aile Sağlığı Merkezi',
 'Çakmak Mah. Atatürk Cad. No:78, Seyhan', 'Adana', 'TR',
 36.9912, 35.3245, '+90 322 363 23 45', true, 'seed', 'general_clinic'),

('Dr. Ayşe Demir - Genel Pratisyen', 'General Practice', 'Demir Tıp Merkezi',
 'Reşatbey Mah. İnönü Cad. No:34, Seyhan', 'Adana', 'TR',
 36.9934, 35.3178, '+90 322 351 34 56', true, 'seed', 'general_clinic'),

('Dr. Ahmet Yılmaz Aile Sağlığı', 'Family Medicine', 'Yılmaz Aile Hekimliği',
 'Kurttepe Mah. Kennedy Cad. No:45, Seyhan', 'Adana', 'TR',
 36.9923, 35.3201, '+90 322 230 56 78', true, 'seed', 'general_clinic'),

('Dr. Elif Kaya İç Hastalıkları', 'Internal Medicine', 'Kaya İç Hastalıkları Polikliniği',
 'Çınarlı Mah. Turhan Cemal Beriker Blv. No:89, Çukurova', 'Adana', 'TR',
 37.0023, 35.3089, '+90 322 233 78 90', true, 'seed', 'general_clinic'),

('Adana Aile Sağlığı Merkezi', 'Family Medicine', 'Adana Aile Sağlığı Merkezi',
 'Güzelyalı Mah. Menderes Cad. No:67, Çukurova', 'Adana', 'TR',
 37.0156, 35.2998, '+90 322 425 45 67', true, 'seed', 'general_clinic'),

('Dr. Zeynep Arslan - Genel Pratisyen', 'General Practice', 'Arslan Tıp Merkezi',
 'Ziyapaşa Bulvarı No:156, Seyhan', 'Adana', 'TR',
 36.9901, 35.3289, '+90 322 363 67 89', true, 'seed', 'general_clinic'),

('Dr. Can Erdoğan Aile Hekimliği', 'Family Medicine', 'Erdoğan Aile Sağlığı',
 'Kurtuluş Mah. Atatürk Cad. No:123, Seyhan', 'Adana', 'TR',
 36.9945, 35.3156, '+90 322 457 90 12', true, 'seed', 'general_clinic'),

('Dr. Selin Yıldız İç Hastalıkları', 'Internal Medicine', 'Yıldız Polikliniği',
 'Gülbahçe Mah. İnönü Cad. No:89, Seyhan', 'Adana', 'TR',
 36.9967, 35.3123, '+90 322 351 12 34', true, 'seed', 'general_clinic'),

('Dr. Murat Çelik Aile Hekimliği', 'Family Medicine', 'Çelik Aile Sağlığı Merkezi',
 'Reşatbey Mah. Gazipaşa Blv. No:45, Seyhan', 'Adana', 'TR',
 36.9978, 35.3189, '+90 322 352 45 67', true, 'seed', 'general_clinic'),

('Dr. Deniz Aydın - Genel Pratisyen', 'General Practice', 'Aydın Tıp Merkezi',
 'Çakmak Mah. Kurtuluş Cad. No:67, Seyhan', 'Adana', 'TR',
 36.9889, 35.3234, '+90 322 363 78 90', true, 'seed', 'general_clinic');

-- ================================================================
-- SPECIALISTS (20 specialist clinics across various specialties)
-- ================================================================

INSERT INTO providers (name, specialty, clinic_name, address, city, country_code, latitude, longitude, phone, is_active, data_source, survey_type)
VALUES
-- CARDIOLOGY
('Prof. Dr. Ahmet Koç - Kardiyoloji', 'Cardiology', 'Koç Kardiyoloji Merkezi',
 'Reşatbey Mah. Turhan Cemal Beriker Blv. No:123, Seyhan', 'Adana', 'TR',
 36.9956, 35.3167, '+90 322 457 12 34', true, 'seed', 'general_clinic'),

('Dr. Mehmet Yavuz Kalp Sağlığı', 'Cardiology', 'Yavuz Kardiyoloji',
 'Kurttepe Mah. Kennedy Cad. No:67, Seyhan', 'Adana', 'TR',
 36.9934, 35.3189, '+90 322 230 67 89', true, 'seed', 'general_clinic'),

-- DERMATOLOGY
('Dr. Ayşe Güneş - Dermatoloji', 'Dermatology', 'Güneş Cilt Sağlığı Merkezi',
 'Çınarlı Mah. Atatürk Cad. No:89, Çukurova', 'Adana', 'TR',
 37.0012, 35.3098, '+90 322 233 56 78', true, 'seed', 'general_clinic'),

('Adana Cilt Hastalıkları Kliniği', 'Dermatology', 'Adana Dermatoloji',
 'Gülbahçe Mah. İnönü Cad. No:45, Seyhan', 'Adana', 'TR',
 36.9978, 35.3134, '+90 322 351 78 90', true, 'seed', 'general_clinic'),

-- OPHTHALMOLOGY
('Prof. Dr. Zeynep Acar - Göz Hastalıkları', 'Ophthalmology', 'Acar Göz Merkezi',
 'Reşatbey Mah. Gazipaşa Cad. No:78, Seyhan', 'Adana', 'TR',
 36.9945, 35.3178, '+90 322 352 90 12', true, 'seed', 'general_clinic'),

('Adana Göz Sağlığı Merkezi', 'Ophthalmology', 'Adana Göz Merkezi',
 'Çakmak Mah. Ziyapaşa Bulvarı No:89, Seyhan', 'Adana', 'TR',
 36.9912, 35.3267, '+90 322 363 45 67', true, 'seed', 'general_clinic'),

-- ORTHOPEDICS
('Op. Dr. Murat Şahin - Ortopedi', 'Orthopedic Surgery', 'Şahin Ortopedi Kliniği',
 'Kurttepe Mah. Turhan Cemal Beriker Blv. No:156, Seyhan', 'Adana', 'TR',
 36.9967, 35.3156, '+90 322 230 12 34', true, 'seed', 'hospital'),

('Adana Ortopedi ve Travmatoloji Merkezi', 'Orthopedic Surgery', 'Adana Ortopedi Merkezi',
 'Güzelyalı Mah. Menderes Cad. No:123, Çukurova', 'Adana', 'TR',
 37.0145, 35.3001, '+90 322 425 67 89', true, 'seed', 'hospital'),

-- GYNECOLOGY
('Op. Dr. Elif Yıldırım - Kadın Doğum', 'Obstetrics & Gynecology', 'Yıldırım Kadın Sağlığı',
 'Reşatbey Mah. İnönü Cad. No:123, Seyhan', 'Adana', 'TR',
 36.9934, 35.3167, '+90 322 351 23 45', true, 'seed', 'general_clinic'),

('Adana Kadın Sağlığı ve Doğum Merkezi', 'Obstetrics & Gynecology', 'Kadın Sağlığı Merkezi',
 'Çınarlı Mah. Turhan Cemal Beriker Blv. No:67, Çukurova', 'Adana', 'TR',
 37.0034, 35.3076, '+90 322 233 34 56', true, 'seed', 'general_clinic'),

-- PEDIATRICS
('Çocuk Doktoru - Dr. Can Özdemir', 'Pediatrics', 'Özdemir Çocuk Sağlığı',
 'Gülbahçe Mah. Atatürk Cad. No:67, Seyhan', 'Adana', 'TR',
 36.9978, 35.3123, '+90 322 351 56 78', true, 'seed', 'general_clinic'),

('Adana Çocuk Hastanesi ve Sağlık Merkezi', 'Pediatrics', 'Adana Çocuk Hastanesi',
 'Çakmak Mah. Kennedy Cad. No:89, Seyhan', 'Adana', 'TR',
 36.9901, 35.3245, '+90 322 363 90 12', true, 'seed', 'general_clinic'),

-- ENT
('Prof. Dr. Ahmet Kılıç - KBB', 'ENT / Otolaryngology', 'Kılıç KBB Merkezi',
 'Reşatbey Mah. Gazipaşa Blv. No:123, Seyhan', 'Adana', 'TR',
 36.9956, 35.3189, '+90 322 352 12 34', true, 'seed', 'general_clinic'),

('Adana Kulak Burun Boğaz Kliniği', 'ENT / Otolaryngology', 'Adana KBB Kliniği',
 'Kurttepe Mah. İnönü Cad. No:45, Seyhan', 'Adana', 'TR',
 36.9923, 35.3201, '+90 322 230 45 67', true, 'seed', 'general_clinic'),

-- UROLOGY
('Op. Dr. Mehmet Aksoy - Üroloji', 'Urology', 'Aksoy Üroloji Merkezi',
 'Çınarlı Mah. Mustafa Kemal Paşa Blv. No:89, Çukurova', 'Adana', 'TR',
 37.0023, 35.3089, '+90 322 233 78 90', true, 'seed', 'general_clinic'),

-- NEUROLOGY
('Prof. Dr. Zeynep Arslan - Nöroloji', 'Neurology', 'Arslan Nöroloji Kliniği',
 'Reşatbey Mah. Turhan Cemal Beriker Blv. No:89, Seyhan', 'Adana', 'TR',
 36.9945, 35.3156, '+90 322 457 23 45', true, 'seed', 'general_clinic'),

-- PSYCHIATRY
('Dr. Selin Yılmaz - Psikiyatri', 'Psychiatry', 'Yılmaz Ruh Sağlığı Merkezi',
 'Gülbahçe Mah. İnönü Cad. No:123, Seyhan', 'Adana', 'TR',
 36.9967, 35.3134, '+90 322 351 67 89', true, 'seed', 'mental_health'),

('Adana Ruh Sağlığı ve Tedavi Merkezi', 'Psychiatry', 'Adana Psikiyatri Merkezi',
 'Çakmak Mah. Ziyapaşa Bulvarı No:67, Seyhan', 'Adana', 'TR',
 36.9912, 35.3278, '+90 322 363 90 12', true, 'seed', 'mental_health'),

-- ONCOLOGY
('Prof. Dr. Ahmet Demir - Onkoloji', 'Oncology', 'Demir Onkoloji Merkezi',
 'Kurttepe Mah. Kennedy Cad. No:123, Seyhan', 'Adana', 'TR',
 36.9934, 35.3189, '+90 322 230 78 90', true, 'seed', 'general_clinic'),

-- GASTROENTEROLOGY
('Dr. Murat Kaya - Gastroenteroloji', 'Gastroenterology', 'Kaya Gastroenteroloji',
 'Çınarlı Mah. Atatürk Cad. No:123, Çukurova', 'Adana', 'TR',
 37.0012, 35.3098, '+90 322 233 12 34', true, 'seed', 'general_clinic');

-- ================================================================
-- AESTHETIC / COSMETIC CLINICS (5 aesthetic clinics)
-- ================================================================

INSERT INTO providers (name, specialty, clinic_name, address, city, country_code, latitude, longitude, phone, is_active, data_source, survey_type)
VALUES
('Adana Estetik Merkezi', 'Aesthetic Medicine', 'Adana Estetik',
 'Reşatbey Mah. Turhan Cemal Beriker Blv. No:234, Seyhan', 'Adana', 'TR',
 36.9967, 35.3167, '+90 322 457 78 90', true, 'seed', 'aesthetics'),

('Dr. Ayşe Çelik - Estetik ve Güzellik', 'Aesthetic Medicine', 'Çelik Estetik Kliniği',
 'Gülbahçe Mah. İnönü Cad. No:89, Seyhan', 'Adana', 'TR',
 36.9978, 35.3123, '+90 322 351 90 12', true, 'seed', 'aesthetics'),

('Adana Saç Ekimi ve Estetik Merkezi', 'Hair Transplant', 'Adana Hair Clinic',
 'Kurttepe Mah. Kennedy Cad. No:78, Seyhan', 'Adana', 'TR',
 36.9923, 35.3201, '+90 322 230 23 45', true, 'seed', 'aesthetics'),

('Beauty Med Estetik - Dr. Zeynep Yılmaz', 'Botox & Fillers', 'Beauty Med Adana',
 'Çınarlı Mah. Mustafa Kemal Paşa Blv. No:156, Çukurova', 'Adana', 'TR',
 37.0034, 35.3089, '+90 322 233 56 78', true, 'seed', 'aesthetics'),

('Adana Lazer ve Cilt Bakım Merkezi', 'Laser Treatments', 'Adana Lazer Merkezi',
 'Reşatbey Mah. Gazipaşa Cad. No:45, Seyhan', 'Adana', 'TR',
 36.9945, 35.3178, '+90 322 352 67 89', true, 'seed', 'aesthetics');

-- ================================================================
-- DIAGNOSTIC CENTERS (4 diagnostic and lab centers)
-- ================================================================

INSERT INTO providers (name, specialty, clinic_name, address, city, country_code, latitude, longitude, phone, is_active, data_source, survey_type)
VALUES
('Adana Tıbbi Görüntüleme Merkezi', 'Radiology', 'Adana Radyoloji',
 'Reşatbey Mah. Turhan Cemal Beriker Blv. No:123, Seyhan', 'Adana', 'TR',
 36.9956, 35.3156, '+90 322 457 34 56', true, 'seed', 'diagnostic'),

('Merkez Laboratuvar ve Patoloji', 'Laboratory / Blood Tests', 'Merkez Lab',
 'Çakmak Mah. Ziyapaşa Bulvarı No:89, Seyhan', 'Adana', 'TR',
 36.9912, 35.3267, '+90 322 363 12 34', true, 'seed', 'diagnostic'),

('Adana MR ve BT Merkezi', 'Radiology', 'Adana Görüntüleme',
 'Kurttepe Mah. Kennedy Cad. No:156, Seyhan', 'Adana', 'TR',
 36.9934, 35.3189, '+90 322 230 56 78', true, 'seed', 'diagnostic'),

('Çukurova Laboratuvar Hizmetleri', 'Laboratory / Blood Tests', 'Çukurova Lab',
 'Çınarlı Mah. Atatürk Cad. No:67, Çukurova', 'Adana', 'TR',
 37.0023, 35.3098, '+90 322 233 90 12', true, 'seed', 'diagnostic');

-- ================================================================
-- PHYSICAL THERAPY & REHABILITATION (3 centers)
-- ================================================================

INSERT INTO providers (name, specialty, clinic_name, address, city, country_code, latitude, longitude, phone, is_active, data_source, survey_type)
VALUES
('Adana Fizik Tedavi ve Rehabilitasyon Merkezi', 'Physical Therapy / Physiotherapy', 'Adana Fizik Tedavi',
 'Gülbahçe Mah. İnönü Cad. No:78, Seyhan', 'Adana', 'TR',
 36.9978, 35.3134, '+90 322 351 45 67', true, 'seed', 'rehabilitation'),

('Çukurova Fizik Tedavi Merkezi', 'Physical Medicine & Rehab', 'Çukurova Fizik Tedavi',
 'Güzelyalı Mah. Menderes Cad. No:89, Çukurova', 'Adana', 'TR',
 37.0145, 35.3001, '+90 322 425 78 90', true, 'seed', 'rehabilitation'),

('Dr. Murat Özkan - Fizik Tedavi Uzmanı', 'Physical Therapy / Physiotherapy', 'Özkan Fizik Tedavi',
 'Reşatbey Mah. Gazipaşa Blv. No:67, Seyhan', 'Adana', 'TR',
 36.9945, 35.3189, '+90 322 352 23 45', true, 'seed', 'rehabilitation');

-- ================================================================
-- SAMPLE REVIEWS (15 realistic Turkish reviews)
-- ================================================================
-- IMPORTANT: Replace '{YOUR_USER_ID}' with your actual Supabase auth user UUID
-- Find it in: Supabase Dashboard > Auth > Users
-- ================================================================

-- Sample reviews for various providers (mix of ratings and feedback)
INSERT INTO reviews (
    provider_id,
    user_id,
    rating_overall,
    rating_wait_time,
    rating_bedside,
    rating_efficacy,
    rating_cleanliness,
    comment,
    visit_date,
    visit_type,
    is_verified,
    status,
    price_level,
    created_at
)
SELECT 
    p.id,
    '{YOUR_USER_ID}'::uuid,
    rating_overall,
    rating_wait_time,
    rating_bedside,
    rating_efficacy,
    rating_cleanliness,
    comment,
    visit_date,
    visit_type,
    is_verified,
    status,
    price_level,
    created_at
FROM providers p
CROSS JOIN (
    VALUES
    -- Reviews for hospitals
    ('Adana Şehir Hastanesi', 5, 4, 5, 5, 5, 'Çok modern bir hastane. Doktorlar ve hemşireler çok ilgili. Kesinlikle tavsiye ederim.', '2026-02-15'::date, 'in_person', true, 'active', 3, NOW() - INTERVAL '5 days'),
    ('Çukurova Üniversitesi Tıp Fakültesi', 4, 3, 4, 4, 4, 'Akademik kadro çok başarılı. Bekleme süreleri biraz uzun olabiliyor ama kaliteli hizmet alıyorsunuz.', '2026-02-10'::date, 'in_person', true, 'active', 2, NOW() - INTERVAL '10 days'),
    ('Medical Park Adana Hastanesi', 5, 5, 5, 5, 5, 'Harika bir deneyim. Her şey çok profesyonel ve temiz. Fiyatlar biraz yüksek ama kalite garantili.', '2026-02-18'::date, 'in_person', true, 'active', 4, NOW() - INTERVAL '2 days'),
    
    -- Reviews for dental clinics
    ('Smile Design Adana', 5, 5, 5, 5, 5, 'Gülüş tasarımım harika oldu! Doktor çok yetenekli ve ekip çok ilgili. Teşekkürler!', '2026-02-12'::date, 'in_person', true, 'active', 3, NOW() - INTERVAL '8 days'),
    ('Adana Diş Polikliniği', 4, 4, 4, 4, 4, 'Diş çekimi için gittim, çok acımadı. Fiyatlar makul ve temizlik çok iyi.', '2026-02-08'::date, 'in_person', false, 'active', 2, NOW() - INTERVAL '12 days'),
    
    -- Reviews for pharmacies
    ('Seyhan Eczanesi', 5, 5, 5, NULL, 5, 'Eczacı çok bilgili ve yardımcı. İlaçlarımı hemen buldum. Teşekkürler!', '2026-02-20'::date, 'in_person', false, 'active', 1, NOW() - INTERVAL '1 day'),
    
    -- Reviews for general practitioners
    ('Dr. Mehmet Öztürk Aile Hekimliği', 5, 4, 5, 5, 4, 'Aile hekimim yıllardır, çok güveniyorum. Her zaman dikkatli muayene ediyor.', '2026-02-14'::date, 'in_person', true, 'active', 1, NOW() - INTERVAL '6 days'),
    ('Dr. Ayşe Demir - Genel Pratisyen', 4, 4, 4, 4, 4, 'İyi bir doktor, açıklamaları çok net ve anlaşılır. Öneriyorum.', '2026-02-16'::date, 'in_person', false, 'active', 2, NOW() - INTERVAL '4 days'),
    
    -- Reviews for specialists
    ('Prof. Dr. Ahmet Koç - Kardiyoloji', 5, 4, 5, 5, 5, 'Kalp sorununla ilgili çok detaylı inceleme yaptı. Profesyonel ve deneyimli bir doktor.', '2026-02-11'::date, 'in_person', true, 'active', 3, NOW() - INTERVAL '9 days'),
    ('Dr. Ayşe Güneş - Dermatoloji', 5, 5, 5, 5, 5, 'Cilt sorunum için harika tedavi önerdi. İki hafta içinde çok iyileştim!', '2026-02-19'::date, 'in_person', true, 'active', 2, NOW() - INTERVAL '2 days'),
    ('Adana Göz Sağlığı Merkezi', 4, 4, 4, 4, 5, 'Göz muayenem çok titiz yapıldı. Cihazlar modern. İyi bir merkez.', '2026-02-13'::date, 'in_person', false, 'active', 2, NOW() - INTERVAL '7 days'),
    ('Çocuk Doktoru - Dr. Can Özdemir', 5, 5, 5, 5, 4, 'Çocuğum çok rahat etti. Doktor çok sabırlı ve güler yüzlü. Kesinlikle tavsiye ederim!', '2026-02-17'::date, 'in_person', true, 'active', 2, NOW() - INTERVAL '3 days'),
    
    -- Reviews for aesthetic clinics
    ('Adana Estetik Merkezi', 5, 5, 5, 5, 5, 'Botoks uygulaması için gittim. Sonuç çok doğal ve güzel oldu. Çok memnunum!', '2026-02-09'::date, 'in_person', true, 'active', 4, NOW() - INTERVAL '11 days'),
    
    -- Reviews for diagnostic centers
    ('Adana Tıbbi Görüntüleme Merkezi', 5, 5, 4, NULL, 5, 'MR çekimi için geldim. Cihazlar çok yeni, sonuçlar hemen hazır. Mükemmel!', '2026-02-15'::date, 'in_person', false, 'active', 2, NOW() - INTERVAL '5 days'),
    
    -- Reviews for physical therapy
    ('Adana Fizik Tedavi ve Rehabilitasyon Merkezi', 4, 4, 4, 5, 4, 'Bel fıtığım için tedavi oldum. Fizyoterapistler çok ilgili ve profesyonel.', '2026-02-10'::date, 'in_person', true, 'active', 2, NOW() - INTERVAL '10 days')
) AS review_data(
    provider_name,
    rating_overall,
    rating_wait_time,
    rating_bedside,
    rating_efficacy,
    rating_cleanliness,
    comment,
    visit_date,
    visit_type,
    is_verified,
    status,
    price_level,
    created_at
)
WHERE p.name = review_data.provider_name;

-- ================================================================
-- SEED COMPLETE!
-- Total providers inserted: 60+
-- - 7 Hospitals
-- - 10 Dental Clinics
-- - 7 Pharmacies
-- - 10 General Practitioners/Family Medicine
-- - 20 Specialists
-- - 5 Aesthetic/Cosmetic Clinics
-- - 4 Diagnostic Centers
-- - 3 Physical Therapy/Rehabilitation Centers
-- Total reviews: 15 sample reviews
-- ================================================================

-- Verify the insert
SELECT 
    survey_type,
    COUNT(*) as provider_count
FROM providers
WHERE city = 'Adana' AND data_source = 'seed'
GROUP BY survey_type
ORDER BY provider_count DESC;

-- Show sample of inserted providers
SELECT name, specialty, clinic_name, city
FROM providers
WHERE city = 'Adana' AND data_source = 'seed'
LIMIT 10;
