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

-- San Francisco orthopedic clinic sample data (all public tables)
INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    aud,
    role,
    created_at,
    updated_at
)
VALUES
    (
        '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
        '00000000-0000-0000-0000-000000000000',
        'owner.sf.ortho@trustcare.dev',
        '$2a$10$CwTycUXWue0Thq9StjUM0uJ8bP0uH/.N/7eXQp6o0n/lbS0w2J4q2',
        NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Dr. Elena Harper","avatar_url":"https://images.unsplash.com/photo-1559839734-2b71ea197ec2"}'::jsonb,
        'authenticated',
        'authenticated',
        NOW(),
        NOW()
    ),
    (
        '1b2c3d4e-5f60-789a-bcde-f0123456789a',
        '00000000-0000-0000-0000-000000000000',
        'patient.sf.ortho@trustcare.dev',
        '$2a$10$CwTycUXWue0Thq9StjUM0uJ8bP0uH/.N/7eXQp6o0n/lbS0w2J4q2',
        NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Jordan Lee","avatar_url":"https://images.unsplash.com/photo-1524504388940-b1c1722653e1"}'::jsonb,
        'authenticated',
        'authenticated',
        NOW(),
        NOW()
    )
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (
    id,
    full_name,
    avatar_url,
    phone,
    country_code,
    preferred_language,
    preferred_currency,
    date_of_birth
)
VALUES
    (
        '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
        'Dr. Elena Harper',
        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2',
        '+1 415 555 0131',
        'US',
        'en',
        'USD',
        '1984-06-12'
    ),
    (
        '1b2c3d4e-5f60-789a-bcde-f0123456789a',
        'Jordan Lee',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1',
        '+1 415 555 0199',
        'US',
        'en',
        'USD',
        '1992-03-04'
    )
ON CONFLICT (id) DO UPDATE
SET
    full_name = EXCLUDED.full_name,
    avatar_url = EXCLUDED.avatar_url,
    phone = EXCLUDED.phone,
    country_code = EXCLUDED.country_code,
    preferred_language = EXCLUDED.preferred_language,
    preferred_currency = EXCLUDED.preferred_currency,
    date_of_birth = EXCLUDED.date_of_birth;

INSERT INTO public.user_roles (id, user_id, role)
VALUES
    ('2c3d4e5f-6071-89ab-cdef-0123456789ab', '0a1b2c3d-4e5f-6789-abcd-ef0123456789', 'user')
ON CONFLICT (user_id, role) DO NOTHING;

INSERT INTO public.providers (
    id,
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
    photo_url,
    cover_url,
    languages_spoken,
    subscription_tier,
    is_featured,
    is_claimed,
    claimed_by,
    claimed_at,
    created_by
)
VALUES (
    '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
    'Bayview Orthopedic Institute',
    'Orthopedic',
    'Bayview Orthopedic Institute',
    '650 Market Street, Suite 2100',
    'San Francisco',
    'US',
    37.7749,
    -122.4194,
    '+1 415 555 0110',
    'hello@bayviewortho.com',
    'https://bayviewortho.com',
    'https://images.unsplash.com/photo-1580281658629-7f915f9d87b1',
    'https://images.unsplash.com/photo-1504814532849-927e54f0b3ad',
    ARRAY['English', 'Spanish'],
    'premium',
    TRUE,
    TRUE,
    '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
    NOW() - INTERVAL '14 days',
    '0a1b2c3d-4e5f-6789-abcd-ef0123456789'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.provider_claims (
    id,
    provider_id,
    claimant_user_id,
    claimant_role,
    business_email,
    phone,
    license_number,
    proof_document_url,
    status,
    reviewed_by,
    reviewed_at
)
VALUES (
    '13579bdf-2468-1357-2468-13579bdf2468',
    '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
    '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
    'owner',
    'billing@bayviewortho.com',
    '+1 415 555 0122',
    'CA-ORTHO-44219',
    'https://example.com/claims/bayview-ortho-proof.pdf',
    'approved',
    '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
    NOW() - INTERVAL '10 days'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.provider_subscriptions (
    id,
    provider_id,
    user_id,
    tier,
    status,
    started_at,
    expires_at,
    auto_renew,
    payment_provider,
    payment_reference,
    monthly_price_cents,
    currency
)
VALUES (
    '2468ace0-1357-2468-1357-2468ace01357',
    '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
    '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
    'premium',
    'active',
    NOW() - INTERVAL '21 days',
    NOW() + INTERVAL '11 months',
    TRUE,
    'stripe',
    'sub_ortho_sf_2026',
    19900,
    'USD'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.provider_services (
    id,
    provider_id,
    category,
    name,
    description,
    price_min,
    price_max,
    currency,
    duration_minutes,
    display_order
)
VALUES
    (
        'f1f1f1f1-1111-2222-3333-444444444444',
        '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
        'Consultation',
        'Orthopedic Consultation',
        'Comprehensive orthopedic evaluation with imaging review.',
        250.00,
        350.00,
        'USD',
        45,
        1
    ),
    (
        'f2f2f2f2-2222-3333-4444-555555555555',
        '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
        'Imaging',
        'Knee MRI Review',
        'Specialist interpretation with treatment recommendations.',
        180.00,
        240.00,
        'USD',
        30,
        2
    ),
    (
        'f3f3f3f3-3333-4444-5555-666666666666',
        '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
        'Rehab',
        'Post-Surgery Recovery Plan',
        'Personalized rehabilitation plan and follow-up check-ins.',
        320.00,
        420.00,
        'USD',
        60,
        3
    )
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.reviews (
    id,
    user_id,
    provider_id,
    visit_date,
    visit_type,
    rating_wait_time,
    rating_bedside,
    rating_efficacy,
    rating_cleanliness,
    rating_overall,
    price_level,
    title,
    comment,
    would_recommend,
    proof_image_url,
    is_verified,
    verification_confidence,
    status,
    helpful_count,
    created_at
)
VALUES
    (
        '12345678-1234-1234-1234-1234567890ab',
        '1b2c3d4e-5f60-789a-bcde-f0123456789a',
        '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
        CURRENT_DATE - INTERVAL '120 days',
        'consultation',
        4,
        5,
        5,
        4,
        4.5,
        3,
        'Clear plan and calm team',
        'Dr. Harper reviewed my MRI in detail, explained next steps clearly, and the staff made the whole visit smooth and reassuring.',
        TRUE,
        'https://example.com/proofs/bayview-ortho-visit.jpg',
        FALSE,
        NULL,
        'pending_verification',
        3,
        NOW() - INTERVAL '118 days'
    ),
    (
        'abcdefab-cdef-cdef-cdef-abcdefabcdef',
        '1b2c3d4e-5f60-789a-bcde-f0123456789a',
        '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
        CURRENT_DATE - INTERVAL '30 days',
        'procedure',
        5,
        5,
        4,
        5,
        4.8,
        3,
        'Excellent post-op follow-up',
        'Follow-up was thorough and proactive, and the recovery plan felt tailored to my lifestyle with helpful check-ins.',
        TRUE,
        NULL,
        FALSE,
        NULL,
        'active',
        1,
        NOW() - INTERVAL '28 days'
    )
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.review_media (
    id,
    review_id,
    user_id,
    media_type,
    storage_path,
    url,
    thumbnail_url,
    file_size_bytes,
    width,
    height,
    display_order
)
VALUES
    (
        '11111111-aaaa-bbbb-cccc-111111111111',
        '12345678-1234-1234-1234-1234567890ab',
        '1b2c3d4e-5f60-789a-bcde-f0123456789a',
        'image',
        'reviews/12345678-1234-1234-1234-1234567890ab/proof-1.jpg',
        'https://example.com/media/bayview-ortho-proof-1.jpg',
        'https://example.com/media/bayview-ortho-proof-1-thumb.jpg',
        182340,
        1280,
        960,
        1
    ),
    (
        '22222222-bbbb-cccc-dddd-222222222222',
        '12345678-1234-1234-1234-1234567890ab',
        '1b2c3d4e-5f60-789a-bcde-f0123456789a',
        'image',
        'reviews/12345678-1234-1234-1234-1234567890ab/proof-2.jpg',
        'https://example.com/media/bayview-ortho-proof-2.jpg',
        'https://example.com/media/bayview-ortho-proof-2-thumb.jpg',
        168004,
        1280,
        960,
        2
    )
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.review_votes (id, review_id, user_id, is_helpful)
VALUES (
    '33333333-cccc-dddd-eeee-333333333333',
    '12345678-1234-1234-1234-1234567890ab',
    '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
    TRUE
)
ON CONFLICT (review_id, user_id) DO NOTHING;

INSERT INTO public.reported_reviews (id, review_id, reporter_id, reason, description, status)
VALUES (
    '44444444-dddd-eeee-ffff-444444444444',
    'abcdefab-cdef-cdef-cdef-abcdefabcdef',
    '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
    'other',
    'Follow-up looks accurate but requires additional clinic verification.',
    'pending'
)
ON CONFLICT (review_id, reporter_id) DO NOTHING;

INSERT INTO public.proof_hashes (id, review_id, image_hash, file_size_bytes)
VALUES (
    '55555555-eeee-ffff-aaaa-555555555555',
    '12345678-1234-1234-1234-1234567890ab',
    'b6a1f2d3e4c5a6b7c8d9e0f1a2b3c4d5',
    182340
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.failed_verifications (id, review_id, error_message, retry_count, resolved)
VALUES (
    '66666666-ffff-aaaa-bbbb-666666666666',
    '12345678-1234-1234-1234-1234567890ab',
    'Vision API timeout during initial scan.',
    1,
    FALSE
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.notifications (id, user_id, type, title, body, data, is_read)
VALUES (
    '77777777-aaaa-bbbb-cccc-777777777777',
    '1b2c3d4e-5f60-789a-bcde-f0123456789a',
    'review_verified',
    'Review verified',
    'Your Bayview Orthopedic Institute review was verified.',
    '{"provider_id":"0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11"}'::jsonb,
    FALSE
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.consent_records (id, user_id, consent_type, version, granted, granted_at)
VALUES
    (
        '88888888-bbbb-cccc-dddd-888888888888',
        '0a1b2c3d-4e5f-6789-abcd-ef0123456789',
        'terms_of_service',
        'v1',
        TRUE,
        NOW() - INTERVAL '30 days'
    ),
    (
        '99999999-cccc-dddd-eeee-999999999999',
        '1b2c3d4e-5f60-789a-bcde-f0123456789a',
        'privacy_policy',
        'v1',
        TRUE,
        NOW() - INTERVAL '30 days'
    )
ON CONFLICT (user_id, consent_type, version) DO NOTHING;

INSERT INTO public.user_events (id, user_id, event_type, event_data, device_info, app_version, session_id)
VALUES (
    'aaaaaaaa-dddd-eeee-ffff-aaaaaaaaaaaa',
    '1b2c3d4e-5f60-789a-bcde-f0123456789a',
    'review_submitted',
    '{"provider_id":"0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11","channel":"ios"}'::jsonb,
    'iPhone 15 Pro',
    '1.0.0',
    'sess_sf_ortho_001'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.provider_campaigns (
    id,
    provider_id,
    campaign_type,
    title,
    description,
    budget_cents,
    currency,
    starts_at,
    ends_at,
    status,
    impressions,
    clicks
)
VALUES (
    'bbbbbbbb-eeee-ffff-aaaa-bbbbbbbbbbbb',
    '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
    'featured_listing',
    'San Francisco Orthopedic Launch',
    'Featured placement for orthopedic launch campaign.',
    50000,
    'USD',
    NOW() - INTERVAL '7 days',
    NOW() + INTERVAL '30 days',
    'active',
    1240,
    84
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.referral_codes (
    id,
    code,
    owner_type,
    owner_provider_id,
    description,
    usage_count,
    max_uses,
    is_active,
    expires_at
)
VALUES (
    'cccccccc-ffff-aaaa-bbbb-cccccccccccc',
    'SFORTHO20',
    'provider',
    '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
    '20 USD off first orthopedic consultation.',
    3,
    100,
    TRUE,
    NOW() + INTERVAL '6 months'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.ai_chat_sessions (id, user_id, title, messages)
VALUES (
    'dddddddd-aaaa-bbbb-cccc-dddddddddddd',
    '1b2c3d4e-5f60-789a-bcde-f0123456789a',
    'Knee pain guidance',
    '[{"role":"user","content":"Looking for an orthopedic specialist in San Francisco."}]'::jsonb
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.appointments (
    id,
    provider_id,
    user_id,
    requested_date,
    requested_time,
    reason,
    insurance_info,
    status
)
VALUES (
    'eeeeeeee-bbbb-cccc-dddd-eeeeeeeeeeee',
    '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
    '1b2c3d4e-5f60-789a-bcde-f0123456789a',
    CURRENT_DATE + INTERVAL '10 days',
    '10:30:00',
    'Follow-up knee pain assessment',
    'Blue Shield PPO',
    'requested'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.contact_requests (
    id,
    provider_id,
    user_id,
    name,
    email,
    phone,
    message,
    is_read
)
VALUES (
    'ffffffff-cccc-dddd-eeee-ffffffffffff',
    '0f6b7a2a-4b8f-4d1c-9f6e-1b7a8c9d0e11',
    '1b2c3d4e-5f60-789a-bcde-f0123456789a',
    'Jordan Lee',
    'patient.sf.ortho@trustcare.dev',
    '+1 415 555 0199',
    'Interested in booking a consultation for knee pain and recovery planning.',
    FALSE
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.feature_flags (flag_name, description, is_enabled, rollout_percentage)
VALUES
    ('ai_verification', 'AI verification of review proofs', TRUE, 100),
    ('video_reviews', 'Video review uploads', TRUE, 100),
    ('ai_health_chat', 'AI health chat assistant', FALSE, 0),
    ('campaigns', 'Provider marketing campaigns', FALSE, 0),
    ('appointments', 'Appointment requests', FALSE, 0),
    ('push_notifications', 'Push notifications', FALSE, 0)
ON CONFLICT (flag_name) DO NOTHING;
