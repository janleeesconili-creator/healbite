create table if not exists public.healbite_admin_payments (
  branch_id text not null references public.healbite_branches(id) on delete cascade,
  payment_month text not null,
  paid boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (branch_id, payment_month)
);

alter table public.healbite_admin_payments enable row level security;
revoke all on public.healbite_admin_payments from anon, authenticated;

create or replace function public.get_healbite_admin_payments(
  p_password text,
  p_month text
)
returns table(branch_id text, paid boolean, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_password <> 'admin2026' then raise exception 'Invalid admin password'; end if;
  return query
  select p.branch_id, p.paid, p.updated_at
  from public.healbite_admin_payments p
  where p.payment_month = p_month
  order by p.branch_id;
end;
$$;

create or replace function public.set_healbite_admin_payment(
  p_password text,
  p_branch text,
  p_month text,
  p_paid boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_password <> 'admin2026' then raise exception 'Invalid admin password'; end if;
  insert into public.healbite_admin_payments (branch_id, payment_month, paid, updated_at)
  values (p_branch, p_month, p_paid, now())
  on conflict (branch_id, payment_month) do update set
    paid = excluded.paid,
    updated_at = now();
end;
$$;

revoke all on function public.get_healbite_admin_payments(text,text) from public;
revoke all on function public.set_healbite_admin_payment(text,text,text,boolean) from public;
grant execute on function public.get_healbite_admin_payments(text,text) to anon, authenticated;
grant execute on function public.set_healbite_admin_payment(text,text,text,boolean) to anon, authenticated;
