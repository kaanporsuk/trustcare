-- Taxonomy search telemetry for miss/high-signal analysis

create table if not exists public.taxonomy_search_logs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  user_id uuid null,
  search_query text not null,
  current_locale text null,
  fallback_locale text null,
  entity_type_filter text null,
  results_count integer not null,
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists idx_taxonomy_search_logs_created_at
  on public.taxonomy_search_logs (created_at desc);

create index if not exists idx_taxonomy_search_logs_locale_created
  on public.taxonomy_search_logs (current_locale, created_at desc);

create index if not exists idx_taxonomy_search_logs_results_created
  on public.taxonomy_search_logs (results_count, created_at desc);

alter table public.taxonomy_search_logs enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'taxonomy_search_logs'
      and policyname = 'taxonomy_search_logs_no_client_read'
  ) then
    create policy taxonomy_search_logs_no_client_read
      on public.taxonomy_search_logs
      for select
      to anon, authenticated
      using (false);
  end if;
end $$;

-- Keep grants explicit; RLS blocks client reads.
revoke all on table public.taxonomy_search_logs from anon, authenticated;

drop function if exists public.search_taxonomy(text, text, text, text);

create function public.search_taxonomy(
  search_query text,
  current_locale text,
  entity_type_filter text default null,
  fallback_locale text default 'en'
)
returns table (
  entity_id text,
  entity_type text,
  label text,
  score real
)
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_query text;
  locale_value text;
  fallback_value text;
  type_filter text;
  emitted_rows integer := 0;
begin
  normalized_query := public.normalize_search_text(search_query);

  if normalized_query = '' then
    return;
  end if;

  locale_value := lower(coalesce(current_locale, 'en'));
  fallback_value := lower(coalesce(fallback_locale, 'en'));
  type_filter := nullif(lower(coalesce(entity_type_filter, '')), '');

  return query
  with candidates as (
    select
      a.entity_id,
      e.entity_type,
      a.locale as alias_locale,
      a.alias_normalized,
      a.weight,
      case
        when a.alias_normalized = normalized_query then 3
        when a.alias_normalized like normalized_query || '%' then 2
        when a.alias_normalized like '%' || normalized_query || '%' then 1
        else 0
      end as match_rank
    from public.taxonomy_aliases a
    join public.taxonomy_entities e
      on e.id = a.entity_id
    where (type_filter is null or e.entity_type = type_filter)
  ),
  current_hits as (
    select count(*)::int as cnt
    from candidates c
    where c.match_rank > 0
      and c.alias_locale = locale_value
  ),
  filtered as (
    select c.*
    from candidates c
    cross join current_hits h
    where c.match_rank > 0
      and (
        (h.cnt > 0 and c.alias_locale = locale_value)
        or
        (h.cnt = 0 and c.alias_locale = fallback_value)
      )
  ),
  best_per_entity as (
    select
      f.entity_id,
      f.entity_type,
      f.alias_normalized,
      (
        (f.weight * 10.0)
        + case f.match_rank
            when 3 then 300.0
            when 2 then 200.0
            else 100.0
          end
      )::real as computed_score,
      row_number() over (
        partition by f.entity_id
        order by f.match_rank desc, f.weight desc, char_length(f.alias_normalized) asc
      ) as rn
    from filtered f
  )
  select
    b.entity_id,
    b.entity_type,
    coalesce(l_local.label, l_fallback.label, l_en.label, e.default_name) as label,
    b.computed_score as score
  from best_per_entity b
  join public.taxonomy_entities e
    on e.id = b.entity_id
  left join public.taxonomy_labels l_local
    on l_local.entity_id = b.entity_id
   and l_local.locale = locale_value
  left join public.taxonomy_labels l_fallback
    on l_fallback.entity_id = b.entity_id
   and l_fallback.locale = fallback_value
  left join public.taxonomy_labels l_en
    on l_en.entity_id = b.entity_id
   and l_en.locale = 'en'
  where b.rn = 1
  order by b.computed_score desc, char_length(b.alias_normalized) asc, label asc
  limit 50;

  get diagnostics emitted_rows = row_count;

  if char_length(normalized_query) >= 3 or emitted_rows = 0 then
    begin
      insert into public.taxonomy_search_logs (
        user_id,
        search_query,
        current_locale,
        fallback_locale,
        entity_type_filter,
        results_count,
        metadata
      ) values (
        auth.uid(),
        normalized_query,
        locale_value,
        fallback_value,
        type_filter,
        emitted_rows,
        jsonb_build_object('logged_by', 'search_taxonomy')
      );
    exception
      when others then
        null;
    end;
  end if;

  return;
end;
$$;

grant execute on function public.search_taxonomy(text, text, text, text)
  to anon, authenticated;
