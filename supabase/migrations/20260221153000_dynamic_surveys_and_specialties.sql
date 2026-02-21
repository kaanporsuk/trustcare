DROP TABLE IF EXISTS specialties CASCADE;

CREATE TABLE specialties (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    name_tr TEXT,
    category TEXT NOT NULL,
    subcategory TEXT,
    icon_name TEXT NOT NULL,
    survey_type TEXT NOT NULL CHECK (survey_type IN (
        'general_clinic', 'dental', 'pharmacy', 'hospital',
        'diagnostic', 'mental_health', 'rehabilitation', 'aesthetics'
    )),
    color_hex TEXT DEFAULT '#0055FF',
    display_order INT DEFAULT 0,
    is_popular BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE
);

ALTER TABLE specialties ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view specialties" ON specialties FOR SELECT USING (true);
CREATE UNIQUE INDEX idx_specialties_name ON specialties(name);
CREATE INDEX idx_specialties_survey_type ON specialties(survey_type);
CREATE INDEX idx_specialties_category ON specialties(category);
CREATE INDEX idx_specialties_popular ON specialties(is_popular) WHERE is_popular = true;

-- PRIMARY CARE
INSERT INTO specialties (name, name_tr, category, icon_name, survey_type, display_order, is_popular) VALUES
('General Practice', 'Genel Pratisyen', 'Primary Care', 'stethoscope', 'general_clinic', 1, true),
('Family Medicine', 'Aile Hekimliği', 'Primary Care', 'house.fill', 'general_clinic', 2, true),
('Internal Medicine', 'İç Hastalıkları', 'Primary Care', 'heart.text.square', 'general_clinic', 3, true),
('Pediatrics', 'Çocuk Sağlığı', 'Primary Care', 'figure.and.child.holdinghands', 'general_clinic', 4, true),
('Geriatrics', 'Geriatri', 'Primary Care', 'figure.walk', 'general_clinic', 5, false);

-- SURGICAL
INSERT INTO specialties (name, name_tr, category, subcategory, icon_name, survey_type, display_order, is_popular) VALUES
('General Surgery', 'Genel Cerrahi', 'Surgical', NULL, 'bandage', 'hospital', 10, false),
('Orthopedic Surgery', 'Ortopedi', 'Surgical', 'Bones & Joints', 'figure.walk', 'hospital', 11, true),
('Cardiovascular Surgery', 'Kalp Damar Cerrahisi', 'Surgical', 'Heart', 'heart.fill', 'hospital', 12, false),
('Neurosurgery', 'Beyin Cerrahisi', 'Surgical', 'Brain & Spine', 'brain.head.profile', 'hospital', 13, false),
('Plastic & Reconstructive Surgery', 'Plastik Cerrahi', 'Surgical', NULL, 'hand.draw', 'hospital', 14, false),
('Thoracic Surgery', 'Göğüs Cerrahisi', 'Surgical', 'Chest', 'lungs', 'hospital', 15, false),
('Vascular Surgery', 'Damar Cerrahisi', 'Surgical', 'Blood Vessels', 'arrow.triangle.branch', 'hospital', 16, false),
('Pediatric Surgery', 'Çocuk Cerrahisi', 'Surgical', NULL, 'figure.and.child.holdinghands', 'hospital', 17, false),
('Transplant Surgery', 'Organ Nakli', 'Surgical', NULL, 'arrow.left.arrow.right', 'hospital', 18, false),
('Bariatric Surgery', 'Obezite Cerrahisi', 'Surgical', 'Weight Loss', 'scalemass', 'hospital', 19, false);

-- MEDICAL SPECIALTIES
INSERT INTO specialties (name, name_tr, category, subcategory, icon_name, survey_type, display_order, is_popular) VALUES
('Cardiology', 'Kardiyoloji', 'Medical', 'Heart', 'heart.fill', 'general_clinic', 20, true),
('Dermatology', 'Dermatoloji', 'Medical', 'Skin', 'hand.raised', 'general_clinic', 21, true),
('Endocrinology', 'Endokrinoloji', 'Medical', 'Hormones & Diabetes', 'pills', 'general_clinic', 22, false),
('Gastroenterology', 'Gastroenteroloji', 'Medical', 'Digestive', 'stomach', 'general_clinic', 23, false),
('Hematology', 'Hematoloji', 'Medical', 'Blood', 'drop.fill', 'general_clinic', 24, false),
('Infectious Disease', 'Enfeksiyon Hastalıkları', 'Medical', NULL, 'microbe', 'general_clinic', 25, false),
('Nephrology', 'Nefroloji', 'Medical', 'Kidneys', 'kidney', 'general_clinic', 26, false),
('Neurology', 'Nöroloji', 'Medical', 'Brain & Nerves', 'brain.head.profile', 'general_clinic', 27, true),
('Oncology', 'Onkoloji', 'Medical', 'Cancer', 'cross.case', 'general_clinic', 28, true),
('Pulmonology', 'Göğüs Hastalıkları', 'Medical', 'Lungs', 'lungs', 'general_clinic', 29, false),
('Rheumatology', 'Romatoloji', 'Medical', 'Joints & Autoimmune', 'figure.walk', 'general_clinic', 30, false),
('Allergy & Immunology', 'Alerji ve İmmünoloji', 'Medical', NULL, 'allergens', 'general_clinic', 31, false),
('Sports Medicine', 'Spor Hekimliği', 'Medical', NULL, 'sportscourt', 'general_clinic', 32, false),
('Pain Management', 'Ağrı Tedavisi', 'Medical', NULL, 'bolt.heart', 'general_clinic', 33, false),
('Sleep Medicine', 'Uyku Bozuklukları', 'Medical', NULL, 'moon.zzz', 'general_clinic', 34, false);

-- WOMEN'S HEALTH
INSERT INTO specialties (name, name_tr, category, subcategory, icon_name, survey_type, display_order, is_popular) VALUES
('Obstetrics & Gynecology', 'Kadın Doğum', 'Women''s Health', NULL, 'person.crop.circle', 'general_clinic', 40, true),
('Reproductive Endocrinology / IVF', 'Tüp Bebek / IVF', 'Women''s Health', 'Fertility', 'heart.circle', 'general_clinic', 41, false),
('Maternal-Fetal Medicine', 'Perinatoloji', 'Women''s Health', 'High-Risk Pregnancy', 'figure.and.child.holdinghands', 'hospital', 42, false),
('Breast Surgery', 'Meme Cerrahisi', 'Women''s Health', NULL, 'cross.case', 'hospital', 43, false),
('Urogynecology', 'Ürojinekoloji', 'Women''s Health', 'Pelvic Floor', 'person.crop.circle', 'general_clinic', 44, false);

-- DENTAL
INSERT INTO specialties (name, name_tr, category, subcategory, icon_name, survey_type, display_order, is_popular) VALUES
('General Dentistry', 'Genel Diş Hekimliği', 'Dental', NULL, 'mouth', 'dental', 50, true),
('Orthodontics', 'Ortodonti', 'Dental', 'Braces & Alignment', 'mouth', 'dental', 51, true),
('Oral Surgery', 'Ağız Cerrahisi', 'Dental', 'Extractions & Implants', 'mouth', 'dental', 52, false),
('Endodontics', 'Endodonti (Kanal Tedavisi)', 'Dental', 'Root Canal', 'mouth', 'dental', 53, false),
('Periodontics', 'Periodontoloji', 'Dental', 'Gums', 'mouth', 'dental', 54, false),
('Prosthodontics', 'Protez', 'Dental', 'Crowns & Bridges', 'mouth', 'dental', 55, false),
('Pediatric Dentistry', 'Çocuk Diş Hekimliği', 'Dental', NULL, 'mouth', 'dental', 56, false),
('Cosmetic Dentistry', 'Estetik Diş Hekimliği', 'Dental', 'Veneers & Whitening', 'sparkles', 'dental', 57, true);

-- EYE CARE
INSERT INTO specialties (name, name_tr, category, subcategory, icon_name, survey_type, display_order, is_popular) VALUES
('Ophthalmology', 'Göz Hastalıkları', 'Eye Care', NULL, 'eye', 'general_clinic', 60, true),
('LASIK / Refractive Surgery', 'LASIK / Göz Lazer', 'Eye Care', 'Vision Correction', 'eye', 'aesthetics', 61, false),
('Retina Specialist', 'Retina Uzmanı', 'Eye Care', NULL, 'eye.circle', 'general_clinic', 62, false),
('Pediatric Ophthalmology', 'Çocuk Göz', 'Eye Care', NULL, 'eye', 'general_clinic', 63, false),
('Optometry', 'Optometri', 'Eye Care', 'Glasses & Contacts', 'eyeglasses', 'general_clinic', 64, false);

-- ENT
INSERT INTO specialties (name, name_tr, category, subcategory, icon_name, survey_type, display_order, is_popular) VALUES
('ENT / Otolaryngology', 'Kulak Burun Boğaz', 'ENT', NULL, 'ear', 'general_clinic', 70, true),
('Audiology', 'Odyoloji', 'ENT', 'Hearing', 'ear', 'general_clinic', 71, false),
('Head & Neck Surgery', 'Baş-Boyun Cerrahisi', 'ENT', NULL, 'person.crop.circle', 'hospital', 72, false),
('Rhinology', 'Rinoloji (Sinüs)', 'ENT', 'Sinus', 'wind', 'general_clinic', 73, false);

-- MENTAL HEALTH
INSERT INTO specialties (name, name_tr, category, icon_name, survey_type, display_order, is_popular) VALUES
('Psychiatry', 'Psikiyatri', 'Mental Health', 'brain', 'mental_health', 80, true),
('Psychology / Therapy', 'Psikoloji / Terapi', 'Mental Health', 'bubble.left.and.bubble.right', 'mental_health', 81, true),
('Child & Adolescent Psychiatry', 'Çocuk Psikiyatrisi', 'Mental Health', 'figure.and.child.holdinghands', 'mental_health', 82, false),
('Addiction Medicine', 'Bağımlılık Tedavisi', 'Mental Health', 'exclamationmark.triangle', 'mental_health', 83, false),
('Neuropsychology', 'Nöropsikoloji', 'Mental Health', 'brain.head.profile', 'mental_health', 84, false);

-- UROLOGY
INSERT INTO specialties (name, name_tr, category, icon_name, survey_type, display_order, is_popular) VALUES
('Urology', 'Üroloji', 'Urology', 'cross.case', 'general_clinic', 90, true),
('Andrology', 'Androloji', 'Urology', 'person.fill', 'general_clinic', 91, false),
('Pediatric Urology', 'Çocuk Ürolojisi', 'Urology', 'figure.and.child.holdinghands', 'general_clinic', 92, false);

-- REHABILITATION
INSERT INTO specialties (name, name_tr, category, icon_name, survey_type, display_order, is_popular) VALUES
('Physical Therapy / Physiotherapy', 'Fizik Tedavi', 'Rehabilitation', 'figure.walk', 'rehabilitation', 100, true),
('Occupational Therapy', 'Ergoterapi', 'Rehabilitation', 'hand.raised', 'rehabilitation', 101, false),
('Speech Therapy', 'Konuşma Terapisi', 'Rehabilitation', 'waveform.and.mic', 'rehabilitation', 102, false),
('Chiropractic', 'Kayropraktik', 'Rehabilitation', 'figure.walk', 'rehabilitation', 103, false),
('Physical Medicine & Rehab', 'Fiziksel Tıp ve Rehabilitasyon', 'Rehabilitation', 'figure.roll', 'rehabilitation', 104, false);

-- AESTHETICS & COSMETIC
INSERT INTO specialties (name, name_tr, category, subcategory, icon_name, survey_type, display_order, is_popular) VALUES
('Aesthetic Medicine', 'Estetik Tıp', 'Aesthetic', NULL, 'sparkles', 'aesthetics', 110, true),
('Botox & Fillers', 'Botoks ve Dolgu', 'Aesthetic', 'Injectables', 'syringe', 'aesthetics', 111, true),
('Hair Transplant', 'Saç Ekimi', 'Aesthetic', 'Hair Restoration', 'comb', 'aesthetics', 112, true),
('Liposuction & Body Contouring', 'Liposuction', 'Aesthetic', 'Body', 'figure.stand', 'aesthetics', 113, false),
('Rhinoplasty', 'Burun Estetiği', 'Aesthetic', 'Nose', 'nose', 'aesthetics', 114, true),
('Facelift & Neck Lift', 'Yüz Germe', 'Aesthetic', 'Face', 'face.smiling', 'aesthetics', 115, false),
('Breast Augmentation / Reduction', 'Meme Estetiği', 'Aesthetic', 'Breast', 'person.crop.circle', 'aesthetics', 116, false),
('Laser Treatments', 'Lazer Tedavisi', 'Aesthetic', 'Skin Resurfacing', 'light.max', 'aesthetics', 117, false),
('Chemical Peels & Microneedling', 'Kimyasal Peeling', 'Aesthetic', 'Skin', 'drop.fill', 'aesthetics', 118, false),
('Eyelid Surgery', 'Göz Kapağı Estetiği', 'Aesthetic', 'Eyes', 'eye', 'aesthetics', 119, false),
('Tummy Tuck', 'Karın Germe', 'Aesthetic', 'Body', 'figure.stand', 'aesthetics', 120, false),
('Lip Enhancement', 'Dudak Dolgusu', 'Aesthetic', 'Lips', 'mouth', 'aesthetics', 121, false),
('Skin Rejuvenation / PRP', 'Cilt Yenileme / PRP', 'Aesthetic', 'Skin', 'sparkles', 'aesthetics', 122, false),
('Tattoo Removal', 'Dövme Silme', 'Aesthetic', 'Skin', 'xmark.circle', 'aesthetics', 123, false),
('Dental Aesthetics (Smile Design)', 'Gülüş Tasarımı', 'Aesthetic', 'Teeth', 'mouth', 'dental', 124, false);

-- DIAGNOSTIC & IMAGING
INSERT INTO specialties (name, name_tr, category, subcategory, icon_name, survey_type, display_order, is_popular) VALUES
('Radiology', 'Radyoloji', 'Diagnostic', 'X-ray & Imaging', 'rays', 'diagnostic', 130, false),
('Pathology', 'Patoloji', 'Diagnostic', 'Lab & Biopsy', 'flask', 'diagnostic', 131, false),
('Nuclear Medicine', 'Nükleer Tıp', 'Diagnostic', NULL, 'atom', 'diagnostic', 132, false),
('Laboratory / Blood Tests', 'Laboratuvar / Kan Testi', 'Diagnostic', NULL, 'testtube.2', 'diagnostic', 133, false);

-- EMERGENCY & URGENT CARE
INSERT INTO specialties (name, name_tr, category, icon_name, survey_type, display_order, is_popular) VALUES
('Emergency Medicine', 'Acil Tıp', 'Emergency', 'cross.case.fill', 'hospital', 140, true),
('Urgent Care / Walk-in Clinic', 'Acil Poliklinik', 'Emergency', 'clock.badge.checkmark', 'hospital', 141, true),
('Trauma Surgery', 'Travma Cerrahisi', 'Emergency', 'staroflife', 'hospital', 142, false);

-- ALTERNATIVE & COMPLEMENTARY
INSERT INTO specialties (name, name_tr, category, icon_name, survey_type, display_order, is_popular) VALUES
('Acupuncture', 'Akupunktur', 'Alternative', 'leaf', 'general_clinic', 150, false),
('Homeopathy', 'Homeopati', 'Alternative', 'leaf.circle', 'general_clinic', 151, false),
('Naturopathy', 'Natüropati', 'Alternative', 'tree', 'general_clinic', 152, false),
('Traditional Chinese Medicine', 'Geleneksel Çin Tıbbı', 'Alternative', 'leaf', 'general_clinic', 153, false),
('Osteopathy', 'Osteopati', 'Alternative', 'hand.raised', 'rehabilitation', 154, false);

-- STANDALONE
INSERT INTO specialties (name, name_tr, category, icon_name, survey_type, display_order, is_popular) VALUES
('Pharmacy', 'Eczane', 'Pharmacy', 'pills.circle', 'pharmacy', 160, true),
('Hospital (General)', 'Hastane (Genel)', 'Hospital', 'building.2', 'hospital', 161, true),
('Nutrition & Dietetics', 'Beslenme ve Diyetetik', 'Other', 'carrot', 'general_clinic', 162, false),
('Podiatry', 'Podoloji', 'Other', 'shoeprints.fill', 'general_clinic', 163, false),
('Genetics & Genomics', 'Genetik', 'Other', 'dna', 'general_clinic', 164, false),
('Palliative Care', 'Palyatif Bakım', 'Other', 'heart.circle', 'hospital', 165, false),
('Wound Care', 'Yara Bakımı', 'Other', 'bandage', 'general_clinic', 166, false);

DROP TRIGGER IF EXISTS trigger_compute_review_overall ON reviews;
DROP TRIGGER IF EXISTS compute_review_overall ON reviews;
DROP FUNCTION IF EXISTS compute_review_overall();
DROP TRIGGER IF EXISTS trigger_calculate_overall ON reviews;
DROP FUNCTION IF EXISTS calculate_overall_rating();

ALTER TABLE reviews ADD COLUMN IF NOT EXISTS survey_type TEXT;
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS valid_survey_type;
ALTER TABLE reviews ADD CONSTRAINT valid_survey_type
    CHECK (survey_type IS NULL OR survey_type IN (
        'general_clinic', 'dental', 'pharmacy', 'hospital',
        'diagnostic', 'mental_health', 'rehabilitation', 'aesthetics'
    ));

ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_pain_mgmt INTEGER CHECK (rating_pain_mgmt BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_accuracy INTEGER CHECK (rating_accuracy BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_knowledge INTEGER CHECK (rating_knowledge BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_courtesy INTEGER CHECK (rating_courtesy BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_care_quality INTEGER CHECK (rating_care_quality BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_admin INTEGER CHECK (rating_admin BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_comfort INTEGER CHECK (rating_comfort BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_turnaround INTEGER CHECK (rating_turnaround BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_empathy INTEGER CHECK (rating_empathy BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_environment INTEGER CHECK (rating_environment BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_communication INTEGER CHECK (rating_communication BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_effectiveness INTEGER CHECK (rating_effectiveness BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_attentiveness INTEGER CHECK (rating_attentiveness BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_equipment INTEGER CHECK (rating_equipment BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_consultation INTEGER CHECK (rating_consultation BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_results INTEGER CHECK (rating_results BETWEEN 1 AND 5);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS rating_aftercare INTEGER CHECK (rating_aftercare BETWEEN 1 AND 5);

UPDATE reviews SET survey_type = 'general_clinic' WHERE survey_type IS NULL;