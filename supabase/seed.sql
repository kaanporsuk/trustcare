-- Seed data for TrustCare

INSERT INTO public.specialties (name_key, name_en, name_de, name_nl, name_pl, name_tr, name_ar, icon_name, display_order, is_active)
VALUES
    ('general_practice', 'General Practice', 'Allgemeinmedizin', 'Huisarts', 'Medycyna rodzinna', 'Aile Hekimligi', 'طب عام', 'stethoscope', 1, TRUE),
    ('dentist', 'Dentist', 'Zahnarzt', 'Tandarts', 'Dentysta', 'Dis Hekimi', 'طب الاسنان', 'mouth', 2, TRUE),
    ('cardiologist', 'Cardiologist', 'Kardiologe', 'Cardioloog', 'Kardiolog', 'Kardiyolog', 'طبيب قلب', 'heart', 3, TRUE),
    ('dermatologist', 'Dermatologist', 'Dermatologe', 'Dermatoloog', 'Dermatolog', 'Dermatolog', 'طبيب جلدية', 'sun.max', 4, TRUE),
    ('pediatrician', 'Pediatrician', 'Kinderarzt', 'Kinderarts', 'Pediatra', 'Cocuk Doktoru', 'طب الاطفال', 'figure.and.child.holdinghands', 5, TRUE),
    ('orthopedic', 'Orthopedic', 'Orthopaede', 'Orthopedist', 'Ortopeda', 'Ortopedist', 'جراحة العظام', 'figure.walk', 6, TRUE),
    ('gynecologist', 'Gynecologist', 'Gynaekologe', 'Gynaecoloog', 'Ginekolog', 'Jinekolog', 'طب النساء', 'figure.stand', 7, TRUE),
    ('psychiatrist', 'Psychiatrist', 'Psychiater', 'Psychiater', 'Psychiatra', 'Psikiyatrist', 'طب نفسي', 'brain.head.profile', 8, TRUE),
    ('ophthalmologist', 'Ophthalmologist', 'Augenarzt', 'Oogarts', 'Okulista', 'Goz Doktoru', 'طب العيون', 'eye', 9, TRUE),
    ('ent', 'ENT', 'HNO-Arzt', 'KNO-arts', 'Laryngolog', 'Kulak Burun Bogaz', 'انف واذن وحنجرة', 'ear', 10, TRUE)
ON CONFLICT (name_key) DO NOTHING;

INSERT INTO public.providers (
    name,
    specialty,
    clinic_name,
    address,
    city,
    country_code,
    latitude,
    longitude,
    phone,
    email,
    website,
    languages_spoken,
    is_active,
    is_featured,
    subscription_tier
)
VALUES
    ('Harbor View Clinic', 'General Practice', 'Harbor View Clinic', '12 King Street', 'London', 'GB', 51.5074, -0.1278, '+44 20 7946 0101', 'hello@harborviewclinic.co.uk', 'https://harborviewclinic.co.uk', ARRAY['English'], TRUE, TRUE, 'basic'),
    ('Spree Medical Center', 'Cardiologist', 'Spree Medical Center', 'Friedrichstrasse 88', 'Berlin', 'DE', 52.5200, 13.4050, '+49 30 1234 5678', 'kontakt@spreemedical.de', 'https://spreemedical.de', ARRAY['Deutsch', 'English'], TRUE, FALSE, 'free'),
    ('Canal Health Group', 'Dermatologist', 'Canal Health Group', 'Prinsengracht 120', 'Amsterdam', 'NL', 52.3676, 4.9041, '+31 20 555 1234', 'info@canalhealth.nl', 'https://canalhealth.nl', ARRAY['Nederlands', 'English'], TRUE, FALSE, 'free'),
    ('Vistula Care', 'Pediatrician', 'Vistula Care', 'Nowy Swiat 25', 'Warsaw', 'PL', 52.2297, 21.0122, '+48 22 555 9876', 'kontakt@vistulacare.pl', 'https://vistulacare.pl', ARRAY['Polski', 'English'], TRUE, FALSE, 'free'),
    ('Cukurova Health', 'Orthopedic', 'Cukurova Health', 'Ataturk Caddesi 45', 'Adana', 'TR', 37.0000, 35.3213, '+90 322 555 4321', 'iletisim@cukurovahealth.com', 'https://cukurovahealth.com', ARRAY['Turkce', 'English'], TRUE, FALSE, 'free');

INSERT INTO public.feature_flags (flag_name, description, is_enabled, rollout_percentage)
VALUES
    ('ai_verification', 'AI verification of review proofs', TRUE, 100),
    ('video_reviews', 'Video review uploads', TRUE, 100),
    ('ai_health_chat', 'AI health chat assistant', FALSE, 0),
    ('campaigns', 'Provider marketing campaigns', FALSE, 0),
    ('appointments', 'Appointment requests', FALSE, 0),
    ('push_notifications', 'Push notifications', FALSE, 0)
ON CONFLICT (flag_name) DO NOTHING;
