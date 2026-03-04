BEGIN;

ALTER TABLE specialties ADD COLUMN IF NOT EXISTS canonical_entity_id text;
ALTER TABLE specialties ADD COLUMN IF NOT EXISTS canonical_entity_type text;

DO $$
BEGIN
  ALTER TABLE specialties
    ADD CONSTRAINT specialties_canonical_entity_type_check
    CHECK (canonical_entity_type IN ('specialty','service','facility'));
EXCEPTION
  WHEN duplicate_object THEN
    NULL;
END $$;

DO $$
BEGIN
  IF to_regclass('public.provider_specialties') IS NULL THEN
    EXECUTE '
      CREATE VIEW public.provider_specialties AS
      SELECT p.id AS provider_id, p.specialty_id
      FROM public.providers p
      WHERE p.specialty_id IS NOT NULL
    ';
  END IF;
END $$;

WITH mapping(legacy_id, entity_id, entity_type) AS (
  VALUES
    -- FACILITIES
    (94, 'FAC_HOSPITAL_GENERAL', 'facility'),
    (93, 'FAC_PHARMACY', 'facility'),
    (84, 'FAC_LABORATORY', 'facility'),
    (86, 'FAC_URGENT_CARE', 'facility'),

    -- SERVICES
    (67, 'SERV_BOTOX_FILLERS', 'service'),
    (74, 'SERV_CHEMICAL_PEEL_MICRONEEDLING', 'service'),
    (73, 'SERV_LASER_TREATMENTS', 'service'),
    (45, 'SERV_LASIK_REFRACTIVE', 'service'),
    (68, 'SERV_HAIR_TRANSPLANT', 'service'),
    (78, 'SERV_PRP_SKIN_REJUVENATION', 'service'),
    (79, 'SERV_TATTOO_REMOVAL', 'service'),
    (77, 'SERV_LIP_ENHANCEMENT', 'service'),
    (69, 'SERV_LIPOSUCTION_BODY_CONTOURING', 'service'),
    (70, 'SERV_RHINOPLASTY', 'service'),
    (71, 'SERV_FACELIFT_NECKLIFT', 'service'),
    (75, 'SERV_EYELID_SURGERY', 'service'),
    (76, 'SERV_TUMMY_TUCK', 'service'),
    (72, 'SERV_BREAST_AUGMENTATION_REDUCTION', 'service'),
    (80, 'SERV_SMILE_DESIGN', 'service'),
    (43, 'SERV_COSMETIC_DENTISTRY', 'service'),
    (88, 'SERV_ACUPUNCTURE', 'service'),
    (89, 'SERV_HOMEOPATHY', 'service'),
    (90, 'SERV_NATUROPATHY', 'service'),
    (91, 'SERV_TCM', 'service'),

    -- SPECIALTIES
    (56, 'SPEC_ADDICTION_MEDICINE', 'specialty'),
    (66, 'SPEC_AESTHETIC_MEDICINE', 'specialty'),
    (27, 'SPEC_ALLERGY_IMMUNOLOGY', 'specialty'),
    (59, 'SPEC_ANDROLOGY', 'specialty'),
    (50, 'SPEC_AUDIOLOGY', 'specialty'),
    (15, 'SPEC_BARIATRIC_SURGERY', 'specialty'),
    (34, 'SPEC_BREAST_SURGERY', 'specialty'),
    (16, 'SPEC_CARDIOLOGY', 'specialty'),
    (8,  'SPEC_CARDIOVASCULAR_SURGERY', 'specialty'),
    (55, 'SPEC_CHILD_ADOLESCENT_PSYCHIATRY', 'specialty'),
    (64, 'SPEC_CHIROPRACTIC', 'specialty'),
    (17, 'SPEC_DERMATOLOGY', 'specialty'),
    (85, 'SPEC_EMERGENCY_MEDICINE', 'specialty'),
    (18, 'SPEC_ENDOCRINOLOGY', 'specialty'),
    (39, 'SPEC_ENDODONTICS', 'specialty'),
    (49, 'SPEC_ENT', 'specialty'),
    (2,  'SPEC_FAMILY_MEDICINE', 'specialty'),
    (19, 'SPEC_GASTROENTEROLOGY', 'specialty'),
    (36, 'SPEC_DENTISTRY_GENERAL', 'specialty'),
    (1,  'SPEC_GENERAL_PRACTICE', 'specialty'),
    (6,  'SPEC_GENERAL_SURGERY', 'specialty'),
    (97, 'SPEC_GENETICS_GENOMICS', 'specialty'),
    (5,  'SPEC_GERIATRICS', 'specialty'),
    (51, 'SPEC_HEAD_NECK_SURGERY', 'specialty'),
    (20, 'SPEC_HEMATOLOGY', 'specialty'),
    (21, 'SPEC_INFECTIOUS_DISEASE', 'specialty'),
    (3,  'SPEC_INTERNAL_MEDICINE', 'specialty'),
    (33, 'SPEC_MATERNAL_FETAL_MEDICINE', 'specialty'),
    (22, 'SPEC_NEPHROLOGY', 'specialty'),
    (23, 'SPEC_NEUROLOGY', 'specialty'),
    (57, 'SPEC_NEUROPSYCHOLOGY', 'specialty'),
    (9,  'SPEC_NEUROSURGERY', 'specialty'),
    (83, 'SPEC_NUCLEAR_MEDICINE', 'specialty'),
    (95, 'SPEC_NUTRITION_DIETETICS', 'specialty'),
    (31, 'SPEC_OBGYN', 'specialty'),
    (62, 'SPEC_OCCUPATIONAL_THERAPY', 'specialty'),
    (24, 'SPEC_ONCOLOGY', 'specialty'),
    (44, 'SPEC_OPHTHALMOLOGY', 'specialty'),
    (48, 'SPEC_OPTOMETRY', 'specialty'),
    (38, 'SPEC_ORAL_SURGERY', 'specialty'),
    (37, 'SPEC_ORTHODONTICS', 'specialty'),
    (7,  'SPEC_ORTHOPEDIC_SURGERY', 'specialty'),
    (92, 'SPEC_OSTEOPATHY', 'specialty'),
    (29, 'SPEC_PAIN_MANAGEMENT', 'specialty'),
    (98, 'SPEC_PALLIATIVE_CARE', 'specialty'),
    (82, 'SPEC_PATHOLOGY', 'specialty'),
    (42, 'SPEC_PEDIATRIC_DENTISTRY', 'specialty'),
    (47, 'SPEC_PEDIATRIC_OPHTHALMOLOGY', 'specialty'),
    (13, 'SPEC_PEDIATRIC_SURGERY', 'specialty'),
    (60, 'SPEC_PEDIATRIC_UROLOGY', 'specialty'),
    (4,  'SPEC_PEDIATRICS', 'specialty'),
    (40, 'SPEC_PERIODONTICS', 'specialty'),
    (65, 'SPEC_PHYSICAL_MEDICINE_REHAB', 'specialty'),
    (61, 'SPEC_PHYSIOTHERAPY', 'specialty'),
    (10, 'SPEC_PLASTIC_RECONSTRUCTIVE_SURGERY', 'specialty'),
    (96, 'SPEC_PODIATRY', 'specialty'),
    (41, 'SPEC_PROSTHODONTICS', 'specialty'),
    (53, 'SPEC_PSYCHIATRY', 'specialty'),
    (54, 'SPEC_PSYCHOLOGY_THERAPY', 'specialty'),
    (25, 'SPEC_PULMONOLOGY', 'specialty'),
    (81, 'SPEC_RADIOLOGY', 'specialty'),
    (32, 'SPEC_REPRODUCTIVE_ENDOCRINOLOGY_IVF', 'specialty'),
    (46, 'SPEC_RETINA_SPECIALIST', 'specialty'),
    (26, 'SPEC_RHEUMATOLOGY', 'specialty'),
    (52, 'SPEC_RHINOLOGY', 'specialty'),
    (30, 'SPEC_SLEEP_MEDICINE', 'specialty'),
    (63, 'SPEC_SPEECH_THERAPY', 'specialty'),
    (28, 'SPEC_SPORTS_MEDICINE', 'specialty'),
    (11, 'SPEC_THORACIC_SURGERY', 'specialty'),
    (14, 'SPEC_TRANSPLANT_SURGERY', 'specialty'),
    (87, 'SPEC_TRAUMA_SURGERY', 'specialty'),
    (35, 'SPEC_UROGYNECOLOGY', 'specialty'),
    (58, 'SPEC_UROLOGY', 'specialty'),
    (12, 'SPEC_VASCULAR_SURGERY', 'specialty'),
    (99, 'SPEC_WOUND_CARE', 'specialty')
)
INSERT INTO taxonomy_entities(id, entity_type, default_name, icon_key, sort_priority)
SELECT m.entity_id,
       m.entity_type,
       s.name,
       s.icon_name,
       COALESCE(s.display_order, 0)
FROM mapping m
JOIN specialties s ON s.id = m.legacy_id
ON CONFLICT (id) DO NOTHING;

UPDATE specialties AS s
SET canonical_entity_id = v.entity_id,
    canonical_entity_type = v.entity_type
FROM (VALUES
  -- FACILITIES
  (94, 'FAC_HOSPITAL_GENERAL', 'facility'),
  (93, 'FAC_PHARMACY', 'facility'),
  (84, 'FAC_LABORATORY', 'facility'),
  (86, 'FAC_URGENT_CARE', 'facility'),

  -- SERVICES
  (67, 'SERV_BOTOX_FILLERS', 'service'),
  (74, 'SERV_CHEMICAL_PEEL_MICRONEEDLING', 'service'),
  (73, 'SERV_LASER_TREATMENTS', 'service'),
  (45, 'SERV_LASIK_REFRACTIVE', 'service'),
  (68, 'SERV_HAIR_TRANSPLANT', 'service'),
  (78, 'SERV_PRP_SKIN_REJUVENATION', 'service'),
  (79, 'SERV_TATTOO_REMOVAL', 'service'),
  (77, 'SERV_LIP_ENHANCEMENT', 'service'),
  (69, 'SERV_LIPOSUCTION_BODY_CONTOURING', 'service'),
  (70, 'SERV_RHINOPLASTY', 'service'),
  (71, 'SERV_FACELIFT_NECKLIFT', 'service'),
  (75, 'SERV_EYELID_SURGERY', 'service'),
  (76, 'SERV_TUMMY_TUCK', 'service'),
  (72, 'SERV_BREAST_AUGMENTATION_REDUCTION', 'service'),
  (80, 'SERV_SMILE_DESIGN', 'service'),
  (43, 'SERV_COSMETIC_DENTISTRY', 'service'),
  (88, 'SERV_ACUPUNCTURE', 'service'),
  (89, 'SERV_HOMEOPATHY', 'service'),
  (90, 'SERV_NATUROPATHY', 'service'),
  (91, 'SERV_TCM', 'service'),

  -- SPECIALTIES (continue for all remaining IDs exactly)
  (56, 'SPEC_ADDICTION_MEDICINE', 'specialty'),
  (66, 'SPEC_AESTHETIC_MEDICINE', 'specialty'),
  (27, 'SPEC_ALLERGY_IMMUNOLOGY', 'specialty'),
  (59, 'SPEC_ANDROLOGY', 'specialty'),
  (50, 'SPEC_AUDIOLOGY', 'specialty'),
  (15, 'SPEC_BARIATRIC_SURGERY', 'specialty'),
  (34, 'SPEC_BREAST_SURGERY', 'specialty'),
  (16, 'SPEC_CARDIOLOGY', 'specialty'),
  (8,  'SPEC_CARDIOVASCULAR_SURGERY', 'specialty'),
  (55, 'SPEC_CHILD_ADOLESCENT_PSYCHIATRY', 'specialty'),
  (64, 'SPEC_CHIROPRACTIC', 'specialty'),
  (17, 'SPEC_DERMATOLOGY', 'specialty'),
  (85, 'SPEC_EMERGENCY_MEDICINE', 'specialty'),
  (18, 'SPEC_ENDOCRINOLOGY', 'specialty'),
  (39, 'SPEC_ENDODONTICS', 'specialty'),
  (49, 'SPEC_ENT', 'specialty'),
  (2,  'SPEC_FAMILY_MEDICINE', 'specialty'),
  (19, 'SPEC_GASTROENTEROLOGY', 'specialty'),
  (36, 'SPEC_DENTISTRY_GENERAL', 'specialty'),
  (1,  'SPEC_GENERAL_PRACTICE', 'specialty'),
  (6,  'SPEC_GENERAL_SURGERY', 'specialty'),
  (97, 'SPEC_GENETICS_GENOMICS', 'specialty'),
  (5,  'SPEC_GERIATRICS', 'specialty'),
  (51, 'SPEC_HEAD_NECK_SURGERY', 'specialty'),
  (20, 'SPEC_HEMATOLOGY', 'specialty'),
  (21, 'SPEC_INFECTIOUS_DISEASE', 'specialty'),
  (3,  'SPEC_INTERNAL_MEDICINE', 'specialty'),
  (33, 'SPEC_MATERNAL_FETAL_MEDICINE', 'specialty'),
  (22, 'SPEC_NEPHROLOGY', 'specialty'),
  (23, 'SPEC_NEUROLOGY', 'specialty'),
  (57, 'SPEC_NEUROPSYCHOLOGY', 'specialty'),
  (9,  'SPEC_NEUROSURGERY', 'specialty'),
  (83, 'SPEC_NUCLEAR_MEDICINE', 'specialty'),
  (95, 'SPEC_NUTRITION_DIETETICS', 'specialty'),
  (31, 'SPEC_OBGYN', 'specialty'),
  (62, 'SPEC_OCCUPATIONAL_THERAPY', 'specialty'),
  (24, 'SPEC_ONCOLOGY', 'specialty'),
  (44, 'SPEC_OPHTHALMOLOGY', 'specialty'),
  (48, 'SPEC_OPTOMETRY', 'specialty'),
  (38, 'SPEC_ORAL_SURGERY', 'specialty'),
  (37, 'SPEC_ORTHODONTICS', 'specialty'),
  (7,  'SPEC_ORTHOPEDIC_SURGERY', 'specialty'),
  (92, 'SPEC_OSTEOPATHY', 'specialty'),
  (29, 'SPEC_PAIN_MANAGEMENT', 'specialty'),
  (98, 'SPEC_PALLIATIVE_CARE', 'specialty'),
  (82, 'SPEC_PATHOLOGY', 'specialty'),
  (42, 'SPEC_PEDIATRIC_DENTISTRY', 'specialty'),
  (47, 'SPEC_PEDIATRIC_OPHTHALMOLOGY', 'specialty'),
  (13, 'SPEC_PEDIATRIC_SURGERY', 'specialty'),
  (60, 'SPEC_PEDIATRIC_UROLOGY', 'specialty'),
  (4,  'SPEC_PEDIATRICS', 'specialty'),
  (40, 'SPEC_PERIODONTICS', 'specialty'),
  (65, 'SPEC_PHYSICAL_MEDICINE_REHAB', 'specialty'),
  (61, 'SPEC_PHYSIOTHERAPY', 'specialty'),
  (10, 'SPEC_PLASTIC_RECONSTRUCTIVE_SURGERY', 'specialty'),
  (96, 'SPEC_PODIATRY', 'specialty'),
  (41, 'SPEC_PROSTHODONTICS', 'specialty'),
  (53, 'SPEC_PSYCHIATRY', 'specialty'),
  (54, 'SPEC_PSYCHOLOGY_THERAPY', 'specialty'),
  (25, 'SPEC_PULMONOLOGY', 'specialty'),
  (81, 'SPEC_RADIOLOGY', 'specialty'),
  (32, 'SPEC_REPRODUCTIVE_ENDOCRINOLOGY_IVF', 'specialty'),
  (46, 'SPEC_RETINA_SPECIALIST', 'specialty'),
  (26, 'SPEC_RHEUMATOLOGY', 'specialty'),
  (52, 'SPEC_RHINOLOGY', 'specialty'),
  (30, 'SPEC_SLEEP_MEDICINE', 'specialty'),
  (63, 'SPEC_SPEECH_THERAPY', 'specialty'),
  (28, 'SPEC_SPORTS_MEDICINE', 'specialty'),
  (11, 'SPEC_THORACIC_SURGERY', 'specialty'),
  (14, 'SPEC_TRANSPLANT_SURGERY', 'specialty'),
  (87, 'SPEC_TRAUMA_SURGERY', 'specialty'),
  (35, 'SPEC_UROGYNECOLOGY', 'specialty'),
  (58, 'SPEC_UROLOGY', 'specialty'),
  (12, 'SPEC_VASCULAR_SURGERY', 'specialty'),
  (99, 'SPEC_WOUND_CARE', 'specialty')
) AS v(legacy_id, entity_id, entity_type)
WHERE s.id = v.legacy_id;

INSERT INTO taxonomy_labels(entity_id, locale, label)
SELECT id, 'en', default_name
FROM taxonomy_entities
ON CONFLICT DO NOTHING;

ALTER TABLE taxonomy_aliases ADD COLUMN IF NOT EXISTS tag text;

INSERT INTO taxonomy_aliases(locale, entity_id, alias_raw, weight, tag)
SELECT 'en', entity_id, label, 1.0, 'label'
FROM taxonomy_labels
WHERE locale='en' AND label IS NOT NULL AND length(trim(label)) > 0
ON CONFLICT DO NOTHING;

INSERT INTO taxonomy_aliases(locale, entity_id, alias_raw, weight, tag)
SELECT 'en', canonical_entity_id, name, 0.9, 'legacy'
FROM specialties
WHERE canonical_entity_id IS NOT NULL AND name IS NOT NULL AND length(trim(name)) > 0
ON CONFLICT DO NOTHING;

INSERT INTO provider_taxonomy(provider_id, entity_id)
SELECT ps.provider_id, s.canonical_entity_id
FROM provider_specialties ps
JOIN specialties s ON s.id = ps.specialty_id
WHERE s.canonical_entity_id IS NOT NULL
ON CONFLICT DO NOTHING;

COMMIT;
