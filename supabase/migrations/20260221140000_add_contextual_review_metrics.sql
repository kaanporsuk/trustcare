-- Add contextual review metrics columns for dynamic survey tailoring
-- These columns store 1-5 scale ratings for various healthcare facility metrics

ALTER TABLE reviews ADD COLUMN IF NOT EXISTS waiting_time INT CHECK (waiting_time IS NULL OR (waiting_time >= 1 AND waiting_time <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS facility_cleanliness INT CHECK (facility_cleanliness IS NULL OR (facility_cleanliness >= 1 AND facility_cleanliness <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS doctor_communication INT CHECK (doctor_communication IS NULL OR (doctor_communication >= 1 AND doctor_communication <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS treatment_outcome INT CHECK (treatment_outcome IS NULL OR (treatment_outcome >= 1 AND treatment_outcome <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS procedural_comfort INT CHECK (procedural_comfort IS NULL OR (procedural_comfort >= 1 AND procedural_comfort <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS clear_explanations INT CHECK (clear_explanations IS NULL OR (clear_explanations >= 1 AND clear_explanations <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS checkout_speed INT CHECK (checkout_speed IS NULL OR (checkout_speed >= 1 AND checkout_speed <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS stock_availability INT CHECK (stock_availability IS NULL OR (stock_availability >= 1 AND stock_availability <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS pharmacist_advice INT CHECK (pharmacist_advice IS NULL OR (pharmacist_advice >= 1 AND pharmacist_advice <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS staff_courtesy INT CHECK (staff_courtesy IS NULL OR (staff_courtesy >= 1 AND staff_courtesy <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS response_time INT CHECK (response_time IS NULL OR (response_time >= 1 AND response_time <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS nursing_care INT CHECK (nursing_care IS NULL OR (nursing_care >= 1 AND nursing_care <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS check_in_process INT CHECK (check_in_process IS NULL OR (check_in_process >= 1 AND check_in_process <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS test_comfort INT CHECK (test_comfort IS NULL OR (test_comfort >= 1 AND test_comfort <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS result_turnaround INT CHECK (result_turnaround IS NULL OR (result_turnaround >= 1 AND result_turnaround <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS session_punctuality INT CHECK (session_punctuality IS NULL OR (session_punctuality >= 1 AND session_punctuality <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS empathy_listening INT CHECK (empathy_listening IS NULL OR (empathy_listening >= 1 AND empathy_listening <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS session_privacy INT CHECK (session_privacy IS NULL OR (session_privacy >= 1 AND session_privacy <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS actionable_advice INT CHECK (actionable_advice IS NULL OR (actionable_advice >= 1 AND actionable_advice <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS therapy_progress INT CHECK (therapy_progress IS NULL OR (therapy_progress >= 1 AND therapy_progress <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS active_supervision INT CHECK (active_supervision IS NULL OR (active_supervision >= 1 AND active_supervision <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS facility_gear INT CHECK (facility_gear IS NULL OR (facility_gear >= 1 AND facility_gear <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS consultation_quality INT CHECK (consultation_quality IS NULL OR (consultation_quality >= 1 AND consultation_quality <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS result_satisfaction INT CHECK (result_satisfaction IS NULL OR (result_satisfaction >= 1 AND result_satisfaction <= 5));
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS aftercare_support INT CHECK (aftercare_support IS NULL OR (aftercare_support >= 1 AND aftercare_support <= 5));

-- Add comment documenting the contextual metrics
COMMENT ON COLUMN reviews.waiting_time IS 'Contextual metric: Waiting time (1-5 scale). Used by clinics, dentists, diagnostic centers.';
COMMENT ON COLUMN reviews.facility_cleanliness IS 'Contextual metric: Facility cleanliness (1-5 scale). Used by clinics, dentists, hospitals, diagnostic centers.';
COMMENT ON COLUMN reviews.doctor_communication IS 'Contextual metric: Doctor communication quality (1-5 scale). Used by general clinics.';
COMMENT ON COLUMN reviews.treatment_outcome IS 'Contextual metric: Treatment outcome satisfaction (1-5 scale). Used by general clinics.';
COMMENT ON COLUMN reviews.procedural_comfort IS 'Contextual metric: Comfort during procedure (1-5 scale). Used by dentists.';
COMMENT ON COLUMN reviews.clear_explanations IS 'Contextual metric: Clarity of explanations (1-5 scale). Used by dentists, mental health.';
COMMENT ON COLUMN reviews.checkout_speed IS 'Contextual metric: Checkout/transaction speed (1-5 scale). Used by pharmacies.';
COMMENT ON COLUMN reviews.stock_availability IS 'Contextual metric: Medication/stock availability (1-5 scale). Used by pharmacies.';
COMMENT ON COLUMN reviews.pharmacist_advice IS 'Contextual metric: Pharmacist guidance quality (1-5 scale). Used by pharmacies.';
COMMENT ON COLUMN reviews.staff_courtesy IS 'Contextual metric: Staff courtesy and professionalism (1-5 scale). Used by pharmacies.';
COMMENT ON COLUMN reviews.response_time IS 'Contextual metric: Response time from medical team (1-5 scale). Used by hospitals.';
COMMENT ON COLUMN reviews.nursing_care IS 'Contextual metric: Nursing staff competence (1-5 scale). Used by hospitals.';
COMMENT ON COLUMN reviews.check_in_process IS 'Contextual metric: Check-in/admission process quality (1-5 scale). Used by hospitals.';
COMMENT ON COLUMN reviews.test_comfort IS 'Contextual metric: Comfort during testing (1-5 scale). Used by diagnostic centers.';
COMMENT ON COLUMN reviews.result_turnaround IS 'Contextual metric: Result delivery timeframe (1-5 scale). Used by diagnostic centers.';
COMMENT ON COLUMN reviews.session_punctuality IS 'Contextual metric: Session start punctuality (1-5 scale). Used by mental health, physical therapy.';
COMMENT ON COLUMN reviews.empathy_listening IS 'Contextual metric: Provider empathy and listening (1-5 scale). Used by mental health, physical therapy.';
COMMENT ON COLUMN reviews.session_privacy IS 'Contextual metric: Privacy and confidentiality (1-5 scale). Used by mental health.';
COMMENT ON COLUMN reviews.actionable_advice IS 'Contextual metric: Actionable advice provided (1-5 scale). Used by mental health, physical therapy.';
COMMENT ON COLUMN reviews.therapy_progress IS 'Contextual metric: Perceived progress in therapy (1-5 scale). Used by mental health, physical therapy.';
COMMENT ON COLUMN reviews.active_supervision IS 'Contextual metric: Active supervision during sessions (1-5 scale). Used by physical therapy.';
COMMENT ON COLUMN reviews.facility_gear IS 'Contextual metric: Equipment and facility quality (1-5 scale). Used by physical therapy, aesthetics.';
COMMENT ON COLUMN reviews.consultation_quality IS 'Contextual metric: Consultation quality (1-5 scale). Used by aesthetics.';
COMMENT ON COLUMN reviews.result_satisfaction IS 'Contextual metric: Result satisfaction (1-5 scale). Used by aesthetics.';
COMMENT ON COLUMN reviews.aftercare_support IS 'Contextual metric: Aftercare support and follow-up (1-5 scale). Used by aesthetics, physical therapy.';

-- Create index on commonly filtered contextual metrics
CREATE INDEX IF NOT EXISTS idx_reviews_contextual_metrics 
ON reviews(waiting_time, facility_cleanliness, doctor_communication, treatment_outcome, checkout_speed);
