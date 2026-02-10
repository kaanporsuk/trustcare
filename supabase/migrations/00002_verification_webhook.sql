-- Review verification webhook trigger

CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE OR REPLACE FUNCTION public.trigger_verify_review()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    base_url TEXT := COALESCE(current_setting('app.settings.supabase_url', true), 'http://127.0.0.1:54321');
    service_key TEXT := current_setting('app.settings.service_role_key', true);
BEGIN
    IF NEW.proof_image_url IS NULL THEN
        RETURN NEW;
    END IF;

    PERFORM net.http_post(
        url := base_url || '/functions/v1/verify-review',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || COALESCE(service_key, '')
        ),
        body := jsonb_build_object('review_id', NEW.id)
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS reviews_verify_trigger ON public.reviews;

CREATE TRIGGER reviews_verify_trigger
AFTER INSERT ON public.reviews
FOR EACH ROW
WHEN (NEW.proof_image_url IS NOT NULL)
EXECUTE FUNCTION public.trigger_verify_review();
