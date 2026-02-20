alter table public.reviews
  add column if not exists rating_staff integer,
  add column if not exists rating_value integer,
  add column if not exists would_recommend boolean default true,
  add column if not exists proof_image_url text,
  add column if not exists is_verified boolean default false,
  add column if not exists status text default 'active';

update public.reviews
set
  rating_staff = coalesce(rating_staff, 3),
  rating_value = coalesce(rating_value, 3),
  would_recommend = coalesce(would_recommend, true),
  is_verified = coalesce(is_verified, false),
  status = coalesce(status, 'active')
where
  rating_staff is null
  or rating_value is null
  or would_recommend is null
  or is_verified is null
  or status is null;

alter table public.reviews
  alter column provider_id set not null,
  alter column user_id set not null,
  alter column visit_date set not null,
  alter column visit_type set not null,
  alter column rating_wait_time set not null,
  alter column rating_bedside set not null,
  alter column rating_efficacy set not null,
  alter column rating_cleanliness set not null,
  alter column rating_staff set not null,
  alter column rating_value set not null,
  alter column rating_overall set not null,
  alter column price_level set not null,
  alter column comment set not null,
  alter column would_recommend set default true,
  alter column is_verified set default false,
  alter column status set default 'active';

alter table public.reviews
  drop constraint if exists reviews_visit_type_check;

alter table public.reviews
  add constraint reviews_visit_type_check
  check (visit_type in ('consultation', 'procedure', 'checkup', 'emergency', 'follow_up'));

alter table public.reviews
  drop constraint if exists reviews_status_check;

alter table public.reviews
  add constraint reviews_status_check
  check (status in ('active', 'pending_verification', 'flagged', 'removed'));

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'reviews_rating_wait_time_check'
      and conrelid = 'public.reviews'::regclass
  ) then
    alter table public.reviews
      add constraint reviews_rating_wait_time_check check (rating_wait_time between 1 and 5);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'reviews_rating_bedside_check'
      and conrelid = 'public.reviews'::regclass
  ) then
    alter table public.reviews
      add constraint reviews_rating_bedside_check check (rating_bedside between 1 and 5);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'reviews_rating_efficacy_check'
      and conrelid = 'public.reviews'::regclass
  ) then
    alter table public.reviews
      add constraint reviews_rating_efficacy_check check (rating_efficacy between 1 and 5);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'reviews_rating_cleanliness_check'
      and conrelid = 'public.reviews'::regclass
  ) then
    alter table public.reviews
      add constraint reviews_rating_cleanliness_check check (rating_cleanliness between 1 and 5);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'reviews_rating_staff_check'
      and conrelid = 'public.reviews'::regclass
  ) then
    alter table public.reviews
      add constraint reviews_rating_staff_check check (rating_staff between 1 and 5);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'reviews_rating_value_check'
      and conrelid = 'public.reviews'::regclass
  ) then
    alter table public.reviews
      add constraint reviews_rating_value_check check (rating_value between 1 and 5);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'reviews_rating_overall_check'
      and conrelid = 'public.reviews'::regclass
  ) then
    alter table public.reviews
      add constraint reviews_rating_overall_check check (rating_overall between 1.0 and 5.0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'reviews_price_level_check'
      and conrelid = 'public.reviews'::regclass
  ) then
    alter table public.reviews
      add constraint reviews_price_level_check check (price_level between 1 and 4);
  end if;
end
$$;

alter table public.reviews enable row level security;

drop policy if exists reviews_insert_own on public.reviews;
create policy reviews_insert_own
  on public.reviews
  for insert
  to authenticated
  with check (auth.uid() = user_id);
