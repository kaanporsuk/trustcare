-- Seed critical multilingual aliases for top specialties and abbreviations.

with entity_map as (
  select 'ENT'::text as key, (
    select id from public.taxonomy_entities where id in ('SPEC_ENT', 'SPEC_ENT_OTOLARYNGOLOGY') order by case id when 'SPEC_ENT' then 0 else 1 end limit 1
  ) as entity_id
  union all
  select 'GP', (
    select id from public.taxonomy_entities where id in ('SPEC_GENERAL_PRACTICE', 'SPEC_FAMILY_MEDICINE') order by case id when 'SPEC_GENERAL_PRACTICE' then 0 else 1 end limit 1
  )
  union all
  select 'DERM', (
    select id from public.taxonomy_entities where id in ('SPEC_DERMATOLOGY') limit 1
  )
  union all
  select 'OBGYN', (
    select id from public.taxonomy_entities where id in ('SPEC_OBGYN') limit 1
  )
  union all
  select 'DENT', (
    select id from public.taxonomy_entities where id in ('SPEC_DENTISTRY_GENERAL', 'SPEC_DENTISTRY') order by case id when 'SPEC_DENTISTRY_GENERAL' then 0 else 1 end limit 1
  )
  union all
  select 'CARD', (
    select id from public.taxonomy_entities where id in ('SPEC_CARDIOLOGY') limit 1
  )
  union all
  select 'PEDS', (
    select id from public.taxonomy_entities where id in ('SPEC_PEDIATRICS') limit 1
  )
  union all
  select 'PSY', (
    select id from public.taxonomy_entities where id in ('SPEC_PSYCHIATRY') limit 1
  )
),
alias_seed(entity_key, locale, alias, weight, source_tag) as (
  values
  -- en
  ('ENT','en','ent',20,'critical_alias_seed'),
  ('GP','en','gp',20,'critical_alias_seed'),
  ('DERM','en','derm',16,'critical_alias_seed'),
  ('OBGYN','en','obgyn',20,'critical_alias_seed'),
  ('DENT','en','dds',14,'critical_alias_seed'),
  ('CARD','en','cardio',16,'critical_alias_seed'),
  ('PEDS','en','peds',16,'critical_alias_seed'),
  ('PSY','en','psych',16,'critical_alias_seed'),

  -- tr
  ('ENT','tr','kbb',20,'critical_alias_seed'),
  ('GP','tr','pratisyen',16,'critical_alias_seed'),
  ('DERM','tr','cildiye',16,'critical_alias_seed'),
  ('OBGYN','tr','kadin dogum',20,'critical_alias_seed'),
  ('DENT','tr','dis hekimi',16,'critical_alias_seed'),
  ('CARD','tr','kardiyoloji',16,'critical_alias_seed'),
  ('PEDS','tr','cocuk doktoru',16,'critical_alias_seed'),
  ('PSY','tr','psikiyatri',16,'critical_alias_seed'),

  -- de
  ('ENT','de','hno',20,'critical_alias_seed'),
  ('GP','de','hausarzt',16,'critical_alias_seed'),
  ('DERM','de','hautarzt',16,'critical_alias_seed'),
  ('OBGYN','de','frauenarzt',18,'critical_alias_seed'),
  ('DENT','de','zahnarzt',16,'critical_alias_seed'),
  ('CARD','de','kardiologe',16,'critical_alias_seed'),
  ('PEDS','de','kinderarzt',16,'critical_alias_seed'),
  ('PSY','de','psychiater',16,'critical_alias_seed'),

  -- pl
  ('ENT','pl','laryngolog',16,'critical_alias_seed'),
  ('GP','pl','lekarz rodzinny',16,'critical_alias_seed'),
  ('DERM','pl','dermatolog',16,'critical_alias_seed'),
  ('OBGYN','pl','ginekolog',16,'critical_alias_seed'),
  ('DENT','pl','dentysta',16,'critical_alias_seed'),
  ('CARD','pl','kardiolog',16,'critical_alias_seed'),
  ('PEDS','pl','pediatra',16,'critical_alias_seed'),
  ('PSY','pl','psychiatra',16,'critical_alias_seed'),

  -- nl
  ('ENT','nl','kno',20,'critical_alias_seed'),
  ('GP','nl','huisarts',16,'critical_alias_seed'),
  ('DERM','nl','dermatoloog',16,'critical_alias_seed'),
  ('OBGYN','nl','gynaecoloog',16,'critical_alias_seed'),
  ('DENT','nl','tandarts',16,'critical_alias_seed'),
  ('CARD','nl','cardioloog',16,'critical_alias_seed'),
  ('PEDS','nl','kinderarts',16,'critical_alias_seed'),
  ('PSY','nl','psychiater',16,'critical_alias_seed'),

  -- da
  ('ENT','da','ore-naese-hals',18,'critical_alias_seed'),
  ('GP','da','praktiserende laege',16,'critical_alias_seed'),
  ('DERM','da','hudlaege',16,'critical_alias_seed'),
  ('OBGYN','da','gynaekolog',16,'critical_alias_seed'),
  ('DENT','da','tandlaege',16,'critical_alias_seed'),
  ('CARD','da','kardiolog',16,'critical_alias_seed'),
  ('PEDS','da','boernelaege',16,'critical_alias_seed'),
  ('PSY','da','psykiater',16,'critical_alias_seed'),

  -- es
  ('ENT','es','otorrino',18,'critical_alias_seed'),
  ('GP','es','medico general',16,'critical_alias_seed'),
  ('DERM','es','dermatologo',16,'critical_alias_seed'),
  ('OBGYN','es','ginecologo',16,'critical_alias_seed'),
  ('DENT','es','dentista',16,'critical_alias_seed'),
  ('CARD','es','cardiologo',16,'critical_alias_seed'),
  ('PEDS','es','pediatra',16,'critical_alias_seed'),
  ('PSY','es','psiquiatra',16,'critical_alias_seed'),

  -- fr
  ('ENT','fr','orl',20,'critical_alias_seed'),
  ('GP','fr','medecin generaliste',16,'critical_alias_seed'),
  ('DERM','fr','dermatologue',16,'critical_alias_seed'),
  ('OBGYN','fr','gynecologue',16,'critical_alias_seed'),
  ('DENT','fr','dentiste',16,'critical_alias_seed'),
  ('CARD','fr','cardiologue',16,'critical_alias_seed'),
  ('PEDS','fr','pediatre',16,'critical_alias_seed'),
  ('PSY','fr','psychiatre',16,'critical_alias_seed'),

  -- it
  ('ENT','it','otorino',18,'critical_alias_seed'),
  ('GP','it','medico di base',16,'critical_alias_seed'),
  ('DERM','it','dermatologo',16,'critical_alias_seed'),
  ('OBGYN','it','ginecologo',16,'critical_alias_seed'),
  ('DENT','it','dentista',16,'critical_alias_seed'),
  ('CARD','it','cardiologo',16,'critical_alias_seed'),
  ('PEDS','it','pediatra',16,'critical_alias_seed'),
  ('PSY','it','psichiatra',16,'critical_alias_seed'),

  -- ro
  ('ENT','ro','orl',20,'critical_alias_seed'),
  ('GP','ro','medic de familie',16,'critical_alias_seed'),
  ('DERM','ro','dermatolog',16,'critical_alias_seed'),
  ('OBGYN','ro','ginecolog',16,'critical_alias_seed'),
  ('DENT','ro','stomatolog',16,'critical_alias_seed'),
  ('CARD','ro','cardiolog',16,'critical_alias_seed'),
  ('PEDS','ro','pediatru',16,'critical_alias_seed'),
  ('PSY','ro','psihiatru',16,'critical_alias_seed'),

  -- pt
  ('ENT','pt','otorrino',18,'critical_alias_seed'),
  ('GP','pt','clinico geral',16,'critical_alias_seed'),
  ('DERM','pt','dermatologista',16,'critical_alias_seed'),
  ('OBGYN','pt','ginecologista',16,'critical_alias_seed'),
  ('DENT','pt','dentista',16,'critical_alias_seed'),
  ('CARD','pt','cardiologista',16,'critical_alias_seed'),
  ('PEDS','pt','pediatra',16,'critical_alias_seed'),
  ('PSY','pt','psiquiatra',16,'critical_alias_seed'),

  -- uk
  ('ENT','uk','lor',20,'critical_alias_seed'),
  ('GP','uk','simeynyy likar',16,'critical_alias_seed'),
  ('DERM','uk','dermatolog',16,'critical_alias_seed'),
  ('OBGYN','uk','ginekolog',16,'critical_alias_seed'),
  ('DENT','uk','stomatolog',16,'critical_alias_seed'),
  ('CARD','uk','kardiolog',16,'critical_alias_seed'),
  ('PEDS','uk','pediatr',16,'critical_alias_seed'),
  ('PSY','uk','psyhiatr',16,'critical_alias_seed'),

  -- ru
  ('ENT','ru','lor',20,'critical_alias_seed'),
  ('GP','ru','terapevt',16,'critical_alias_seed'),
  ('DERM','ru','dermatolog',16,'critical_alias_seed'),
  ('OBGYN','ru','ginekolog',16,'critical_alias_seed'),
  ('DENT','ru','stomatolog',16,'critical_alias_seed'),
  ('CARD','ru','kardiolog',16,'critical_alias_seed'),
  ('PEDS','ru','pediatr',16,'critical_alias_seed'),
  ('PSY','ru','psihiatr',16,'critical_alias_seed'),

  -- sv
  ('ENT','sv','oron nasa hals',18,'critical_alias_seed'),
  ('GP','sv','allmanlakare',16,'critical_alias_seed'),
  ('DERM','sv','hudlakare',16,'critical_alias_seed'),
  ('OBGYN','sv','gynekolog',16,'critical_alias_seed'),
  ('DENT','sv','tandlakare',16,'critical_alias_seed'),
  ('CARD','sv','kardiolog',16,'critical_alias_seed'),
  ('PEDS','sv','barnlakare',16,'critical_alias_seed'),
  ('PSY','sv','psykiater',16,'critical_alias_seed'),

  -- cs
  ('ENT','cs','orl',20,'critical_alias_seed'),
  ('GP','cs','prakticky lekar',16,'critical_alias_seed'),
  ('DERM','cs','dermatolog',16,'critical_alias_seed'),
  ('OBGYN','cs','gynekolog',16,'critical_alias_seed'),
  ('DENT','cs','zubar',16,'critical_alias_seed'),
  ('CARD','cs','kardiolog',16,'critical_alias_seed'),
  ('PEDS','cs','pediatr',16,'critical_alias_seed'),
  ('PSY','cs','psychiatr',16,'critical_alias_seed'),

  -- hu
  ('ENT','hu','ful orr gegesz',18,'critical_alias_seed'),
  ('GP','hu','haziorvos',16,'critical_alias_seed'),
  ('DERM','hu','borgyogyasz',16,'critical_alias_seed'),
  ('OBGYN','hu','nogyogyasz',16,'critical_alias_seed'),
  ('DENT','hu','fogorvos',16,'critical_alias_seed'),
  ('CARD','hu','kardiologus',16,'critical_alias_seed'),
  ('PEDS','hu','gyermekorvos',16,'critical_alias_seed'),
  ('PSY','hu','pszichiater',16,'critical_alias_seed')
)
insert into public.taxonomy_aliases (entity_id, locale, alias_raw, weight, tag)
select
  em.entity_id,
  a.locale,
  a.alias,
  a.weight,
  a.source_tag
from alias_seed a
join entity_map em on em.key = a.entity_key
where em.entity_id is not null
on conflict (locale, alias_normalized, entity_id) do nothing;
