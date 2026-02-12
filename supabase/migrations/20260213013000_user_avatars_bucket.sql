insert into storage.buckets (id, name, public)
values ('user-avatars', 'user-avatars', true)
on conflict (id) do update set public = excluded.public;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'User avatars read'
  ) then
    create policy "User avatars read"
      on storage.objects for select
      using (bucket_id = 'user-avatars');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'User avatars insert'
  ) then
    create policy "User avatars insert"
      on storage.objects for insert
      with check (
        bucket_id = 'user-avatars'
        and auth.uid()::text = (storage.foldername(name))[1]
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'User avatars update'
  ) then
    create policy "User avatars update"
      on storage.objects for update
      using (
        bucket_id = 'user-avatars'
        and auth.uid()::text = (storage.foldername(name))[1]
      )
      with check (
        bucket_id = 'user-avatars'
        and auth.uid()::text = (storage.foldername(name))[1]
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'User avatars delete'
  ) then
    create policy "User avatars delete"
      on storage.objects for delete
      using (
        bucket_id = 'user-avatars'
        and auth.uid()::text = (storage.foldername(name))[1]
      );
  end if;
end $$;
