ALTER TABLE public.reviews
    ADD COLUMN IF NOT EXISTS rating_staff INTEGER CHECK (rating_staff BETWEEN 1 AND 5),
    ADD COLUMN IF NOT EXISTS rating_value INTEGER CHECK (rating_value BETWEEN 1 AND 5);

ALTER TABLE public.reviews
    ALTER COLUMN rating_staff SET DEFAULT 3,
    ALTER COLUMN rating_value SET DEFAULT 3;

UPDATE public.reviews
SET rating_staff = COALESCE(rating_staff, 3),
    rating_value = COALESCE(rating_value, 3);

ALTER TABLE public.reviews
    ALTER COLUMN rating_staff SET NOT NULL,
    ALTER COLUMN rating_value SET NOT NULL;

ALTER TABLE public.reviews
    DROP CONSTRAINT IF EXISTS reviews_visit_type_check;

ALTER TABLE public.reviews
    ADD CONSTRAINT reviews_visit_type_check
    CHECK (visit_type IN ('consultation', 'procedure', 'checkup', 'emergency', 'follow_up'));
