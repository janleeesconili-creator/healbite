create table if not exists public.healbite_branches (
  id text primary key,
  name text not null unique,
  initials text not null,
  created_at timestamptz not null default now()
);

insert into public.healbite_branches (id, name, initials) values
  ('baclaran', 'Healbite Baclaran', 'HB'),
  ('gtuazon', 'Healbite G. Tuazon', 'HG'),
  ('zanicare', 'Zanicare Parañaque', 'ZP'),
  ('mandaluyong', 'Healbite Mandaluyong', 'HM'),
  ('pasig', 'Healbite Pasig', 'HP'),
  ('staana', 'Healbite Sta. Ana', 'HA'),
  ('sanandres', 'Healbite San Andres', 'HS'),
  ('kalayaanpasay', 'Healbite Kalayaan Pasay', 'KP'),
  ('taytay', 'Healbite Taytay', 'HT')
on conflict (id) do update
set name = excluded.name, initials = excluded.initials;

alter table public.healbite_branches enable row level security;
revoke all on public.healbite_branches from anon, authenticated;

create or replace function public.get_healbite_branches()
returns setof public.healbite_branches
language sql
security definer
set search_path = public
as $$
  select * from public.healbite_branches order by created_at, name;
$$;

create or replace function public.add_healbite_branch(
  p_pin text,
  p_name text,
  p_initials text
)
returns setof public.healbite_branches
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id text := regexp_replace(lower(trim(p_name)), '[^a-z0-9]+', '', 'g');
begin
  if p_pin <> '2026' then
    raise exception 'Invalid PIN';
  end if;
  if length(trim(p_name)) < 3 or length(v_id) < 2 then
    raise exception 'Invalid branch name';
  end if;
  if length(trim(p_initials)) < 1 or length(trim(p_initials)) > 3 then
    raise exception 'Invalid initials';
  end if;

  return query
  insert into public.healbite_branches (id, name, initials)
  values (v_id, trim(p_name), upper(trim(p_initials)))
  returning *;
end;
$$;

revoke all on function public.get_healbite_branches() from public;
revoke all on function public.add_healbite_branch(text, text, text) from public;
grant execute on function public.get_healbite_branches() to anon, authenticated;
grant execute on function public.add_healbite_branch(text, text, text) to anon, authenticated;
