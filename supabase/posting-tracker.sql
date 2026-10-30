create table if not exists public.healbite_posting_marks (
  branch_id text not null references public.healbite_branches(id) on delete cascade,
  post_date date not null,
  created_at timestamptz not null default now(),
  primary key (branch_id, post_date)
);

alter table public.healbite_posting_marks enable row level security;
revoke all on public.healbite_posting_marks from anon, authenticated;

create or replace function public.get_healbite_posting_marks(
  p_pin text,
  p_branch text,
  p_month text
)
returns table (post_date text)
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_pin <> '2026' then raise exception 'Invalid PIN'; end if;
  return query
  select to_char(m.post_date, 'YYYY-MM-DD')
  from public.healbite_posting_marks m
  where m.branch_id = p_branch
    and to_char(m.post_date, 'YYYY-MM') = p_month
  order by m.post_date;
end;
$$;

create or replace function public.set_healbite_posting_mark(
  p_pin text,
  p_branch text,
  p_date date,
  p_marked boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_pin <> '2026' then raise exception 'Invalid PIN'; end if;
  if p_marked then
    insert into public.healbite_posting_marks (branch_id, post_date)
    values (p_branch, p_date)
    on conflict do nothing;
  else
    delete from public.healbite_posting_marks
    where branch_id = p_branch and post_date = p_date;
  end if;
end;
$$;

revoke all on function public.get_healbite_posting_marks(text, text, text) from public;
revoke all on function public.set_healbite_posting_mark(text, text, date, boolean) from public;
grant execute on function public.get_healbite_posting_marks(text, text, text) to anon, authenticated;
grant execute on function public.set_healbite_posting_mark(text, text, date, boolean) to anon, authenticated;
