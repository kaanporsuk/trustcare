insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'review-media',
    'review-media',
    true,
    52428800,
    array['image/jpeg', 'image/png', 'image/heic', 'video/mp4', 'video/quicktime']
  ),
  (
    'verification-proofs',
    'verification-proofs',
    false,
    10485760,
    array['image/jpeg', 'image/png', 'image/heic']
  )
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists tc_review_media_insert_auth on storage.objects;
create policy tc_review_media_insert_auth
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'review-media'
    and auth.uid() is not null
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists tc_review_media_select_public on storage.objects;
create policy tc_review_media_select_public
  on storage.objects
  for select
  to public
  using (bucket_id = 'review-media');

drop policy if exists tc_verification_proofs_insert_auth on storage.objects;
create policy tc_verification_proofs_insert_auth
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'verification-proofs'
    and auth.uid() is not null
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists tc_verification_proofs_select_owner_or_admin on storage.objects;
create policy tc_verification_proofs_select_owner_or_admin
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'verification-proofs'
    and (
      auth.uid()::text = (storage.foldername(name))[1]
      or public.is_admin()
    )
  );
