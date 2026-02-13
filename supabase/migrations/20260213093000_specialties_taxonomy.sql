-- Drop existing if needed
DROP TABLE IF EXISTS specialties CASCADE;

CREATE TABLE specialties (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    subcategory TEXT,
    icon_name TEXT NOT NULL,
    display_order INT DEFAULT 0,
    is_popular BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE
);

ALTER TABLE specialties ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view specialties" ON specialties FOR SELECT USING (true);

-- CATEGORY: PRIMARY CARE
INSERT INTO specialties (name, category, subcategory, icon_name, display_order, is_popular) VALUES
('General Practice', 'Primary Care', NULL, 'stethoscope', 1, true),
('Family Medicine', 'Primary Care', NULL, 'house.fill', 2, true),
('Internal Medicine', 'Primary Care', NULL, 'heart.text.square', 3, true),
('Pediatrics', 'Primary Care', NULL, 'figure.and.child.holdinghands', 4, true),
('Geriatrics', 'Primary Care', NULL, 'figure.walk', 5, false);

-- CATEGORY: SURGICAL SPECIALTIES
INSERT INTO specialties (name, category, subcategory, icon_name, display_order, is_popular) VALUES
('General Surgery', 'Surgical', NULL, 'bandage', 10, false),
('Orthopedic Surgery', 'Surgical', 'Bones & Joints', 'figure.walk', 11, true),
('Cardiovascular Surgery', 'Surgical', 'Heart', 'heart.fill', 12, false),
('Neurosurgery', 'Surgical', 'Brain & Spine', 'brain.head.profile', 13, false),
('Plastic & Reconstructive Surgery', 'Surgical', NULL, 'hand.draw', 14, false),
('Thoracic Surgery', 'Surgical', 'Chest', 'lungs', 15, false),
('Vascular Surgery', 'Surgical', 'Blood Vessels', 'arrow.triangle.branch', 16, false),
('Pediatric Surgery', 'Surgical', NULL, 'figure.and.child.holdinghands', 17, false),
('Transplant Surgery', 'Surgical', NULL, 'arrow.left.arrow.right', 18, false),
('Bariatric Surgery', 'Surgical', 'Weight Loss', 'scalemass', 19, false);

-- CATEGORY: MEDICAL SPECIALTIES
INSERT INTO specialties (name, category, subcategory, icon_name, display_order, is_popular) VALUES
('Cardiology', 'Medical', 'Heart', 'heart.fill', 20, true),
('Dermatology', 'Medical', 'Skin', 'hand.raised', 21, true),
('Endocrinology', 'Medical', 'Hormones & Diabetes', 'pills', 22, false),
('Gastroenterology', 'Medical', 'Digestive', 'stomach', 23, false),
('Hematology', 'Medical', 'Blood', 'drop.fill', 24, false),
('Infectious Disease', 'Medical', NULL, 'microbe', 25, false),
('Nephrology', 'Medical', 'Kidneys', 'kidney', 26, false),
('Neurology', 'Medical', 'Brain & Nerves', 'brain.head.profile', 27, true),
('Oncology', 'Medical', 'Cancer', 'cross.case', 28, true),
('Pulmonology', 'Medical', 'Lungs', 'lungs', 29, false),
('Rheumatology', 'Medical', 'Joints & Autoimmune', 'figure.walk', 30, false),
('Allergy & Immunology', 'Medical', NULL, 'allergens', 31, false),
('Sports Medicine', 'Medical', NULL, 'sportscourt', 32, false),
('Pain Management', 'Medical', NULL, 'bolt.heart', 33, false),
('Sleep Medicine', 'Medical', NULL, 'moon.zzz', 34, false);

-- CATEGORY: WOMEN'S HEALTH
INSERT INTO specialties (name, category, subcategory, icon_name, display_order, is_popular) VALUES
('Obstetrics & Gynecology', 'Women''s Health', NULL, 'person.crop.circle', 40, true),
('Reproductive Endocrinology / IVF', 'Women''s Health', 'Fertility', 'heart.circle', 41, false),
('Maternal-Fetal Medicine', 'Women''s Health', 'High-Risk Pregnancy', 'figure.and.child.holdinghands', 42, false),
('Breast Surgery', 'Women''s Health', NULL, 'cross.case', 43, false),
('Urogynecology', 'Women''s Health', 'Pelvic Floor', 'person.crop.circle', 44, false);

-- CATEGORY: DENTAL
INSERT INTO specialties (name, category, subcategory, icon_name, display_order, is_popular) VALUES
('General Dentistry', 'Dental', NULL, 'mouth', 50, true),
('Orthodontics', 'Dental', 'Braces & Alignment', 'mouth', 51, true),
('Oral Surgery', 'Dental', 'Extractions & Implants', 'mouth', 52, false),
('Endodontics', 'Dental', 'Root Canal', 'mouth', 53, false),
('Periodontics', 'Dental', 'Gums', 'mouth', 54, false),
('Prosthodontics', 'Dental', 'Crowns & Bridges', 'mouth', 55, false),
('Pediatric Dentistry', 'Dental', NULL, 'mouth', 56, false),
('Cosmetic Dentistry', 'Dental', 'Veneers & Whitening', 'sparkles', 57, true);

-- CATEGORY: EYE CARE
INSERT INTO specialties (name, category, subcategory, icon_name, display_order, is_popular) VALUES
('Ophthalmology', 'Eye Care', NULL, 'eye', 60, true),
('LASIK / Refractive Surgery', 'Eye Care', 'Vision Correction', 'eye', 61, false),
('Retina Specialist', 'Eye Care', NULL, 'eye.circle', 62, false),
('Pediatric Ophthalmology', 'Eye Care', NULL, 'eye', 63, false),
('Optometry', 'Eye Care', 'Glasses & Contacts', 'eyeglasses', 64, false);

-- CATEGORY: EAR, NOSE & THROAT
INSERT INTO specialties (name, category, subcategory, icon_name, display_order, is_popular) VALUES
('ENT / Otolaryngology', 'ENT', NULL, 'ear', 70, true),
('Audiology', 'ENT', 'Hearing', 'ear', 71, false),
('Head & Neck Surgery', 'ENT', NULL, 'person.crop.circle', 72, false),
('Rhinology', 'ENT', 'Sinus', 'wind', 73, false);

-- CATEGORY: MENTAL HEALTH
INSERT INTO specialties (name, category, subcategory, icon_name, display_order, is_popular) VALUES
('Psychiatry', 'Mental Health', NULL, 'brain', 80, true),
('Psychology', 'Mental Health', 'Therapy & Counseling', 'bubble.left.and.bubble.right', 81, true),
('Child & Adolescent Psychiatry', 'Mental Health', NULL, 'figure.and.child.holdinghands', 82, false),
('Addiction Medicine', 'Mental Health', NULL, 'exclamationmark.triangle', 83, false),
('Neuropsychology', 'Mental Health', NULL, 'brain.head.profile', 84, false);

-- CATEGORY: UROLOGY & REPRODUCTIVE
INSERT INTO specialties (name, category, subcategory, icon_name, display_order, is_popular) VALUES
('Urology', 'Urology', NULL, 'cross.case', 90, true),
('Andrology', 'Urology', 'Male Fertility', 'person.fill', 91, false),
('Pediatric Urology', 'Urology', NULL, 'figure.and.child.holdinghands', 92, false);

-- CATEGORY: REHABILITATION & THERAPY
INSERT INTO specialties (name, category, subcategory, icon_name, display_order, is_popular) VALUES
('Physical Therapy / Physiotherapy', 'Rehabilitation', NULL, 'figure.walk', 100, true),
('Occupational Therapy', 'Rehabilitation', NULL, 'hand.raised', 101, false),
('Speech Therapy', 'Rehabilitation', NULL, 'waveform.and.mic', 102, false),
('Chiropractic', 'Rehabilitation', 'Spine Alignment', 'figure.walk', 103, false),
('Physical Medicine & Rehabilitation', 'Rehabilitation', NULL, 'figure.roll', 104, false);

-- CATEGORY: AESTHETIC & COSMETIC
INSERT INTO specialties (name, category, subcategory, icon_name, display_order, is_popular) VALUES
('Aesthetic Medicine', 'Aesthetic', NULL, 'sparkles', 110, true),
('Botox & Fillers', 'Aesthetic', 'Injectables', 'syringe', 111, true),
('Hair Transplant', 'Aesthetic', 'Hair Restoration', 'comb', 112, true),
('Liposuction & Body Contouring', 'Aesthetic', 'Body', 'figure.stand', 113, false),
('Rhinoplasty', 'Aesthetic', 'Nose', 'nose', 114, true),
('Facelift & Neck Lift', 'Aesthetic', 'Face', 'face.smiling', 115, false),
('Breast Augmentation / Reduction', 'Aesthetic', 'Breast', 'person.crop.circle', 116, false),
('Laser Treatments', 'Aesthetic', 'Skin Resurfacing', 'light.max', 117, false),
('Chemical Peels & Microneedling', 'Aesthetic', 'Skin', 'drop.fill', 118, false),
('Eyelid Surgery (Blepharoplasty)', 'Aesthetic', 'Eyes', 'eye', 119, false),
('Tummy Tuck (Abdominoplasty)', 'Aesthetic', 'Body', 'figure.stand', 120, false),
('Lip Enhancement', 'Aesthetic', 'Lips', 'mouth', 121, false),
('Skin Rejuvenation / PRP', 'Aesthetic', 'Skin', 'sparkles', 122, false),
('Tattoo Removal', 'Aesthetic', 'Skin', 'xmark.circle', 123, false),
('Dental Aesthetics (Smile Design)', 'Aesthetic', 'Teeth', 'mouth', 124, false);

-- CATEGORY: DIAGNOSTIC & IMAGING
INSERT INTO specialties (name, category, subcategory, icon_name, display_order, is_popular) VALUES
('Radiology', 'Diagnostic', 'X-ray & Imaging', 'rays', 130, false),
('Pathology', 'Diagnostic', 'Lab & Biopsy', 'flask', 131, false),
('Nuclear Medicine', 'Diagnostic', NULL, 'atom', 132, false),
('Laboratory / Blood Tests', 'Diagnostic', NULL, 'testtube.2', 133, false);

-- CATEGORY: EMERGENCY & URGENT
INSERT INTO specialties (name, category, subcategory, icon_name, display_order, is_popular) VALUES
('Emergency Medicine', 'Emergency', NULL, 'cross.case.fill', 140, true),
('Urgent Care / Walk-in Clinic', 'Emergency', NULL, 'clock.badge.checkmark', 141, true),
('Trauma Surgery', 'Emergency', NULL, 'staroflife', 142, false);

-- CATEGORY: ALTERNATIVE & COMPLEMENTARY
INSERT INTO specialties (name, category, subcategory, icon_name, display_order, is_popular) VALUES
('Acupuncture', 'Alternative', NULL, 'leaf', 150, false),
('Homeopathy', 'Alternative', NULL, 'leaf.circle', 151, false),
('Naturopathy', 'Alternative', NULL, 'tree', 152, false),
('Traditional Chinese Medicine', 'Alternative', NULL, 'leaf', 153, false),
('Osteopathy', 'Alternative', NULL, 'hand.raised', 154, false);

-- CATEGORY: OTHER SPECIALTIES
INSERT INTO specialties (name, category, subcategory, icon_name, display_order, is_popular) VALUES
('Nutrition & Dietetics', 'Other', NULL, 'carrot', 160, false),
('Pharmacy', 'Other', NULL, 'pills.circle', 161, false),
('Podiatry', 'Other', 'Foot Care', 'shoeprints.fill', 162, false),
('Genetics & Genomics', 'Other', NULL, 'dna', 163, false),
('Palliative Care', 'Other', 'End of Life', 'heart.circle', 164, false),
('Wound Care', 'Other', NULL, 'bandage', 165, false);
