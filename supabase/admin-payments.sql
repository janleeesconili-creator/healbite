create table if not exists public.healbite_admin_payments (
  branch_id text not null references public.healbite_branches(id) on delete cascade,
  payment_month text not null,
  paid boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (branch_id, payment_month)
);

alter table public.healbite_admin_payments add column if not exists receipt_name text;
alter table public.healbite_admin_payments add column if not exists receipt_mime text;
alter table public.healbite_admin_payments add column if not exists receipt_data text;
alter table public.healbite_admin_payments add column if not exists amount_paid numeric not null default 0;

alter table public.healbite_admin_payments enable row level security;
revoke all on public.healbite_admin_payments from anon, authenticated;

drop function if exists public.get_healbite_admin_payments(text,text);
create function public.get_healbite_admin_payments(
  p_password text,
  p_month text
)
returns table(branch_id text, paid boolean, amount_paid numeric, updated_at timestamptz, receipt_name text)
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_password <> 'admin2026' then raise exception 'Invalid admin password'; end if;
  return query
  select p.branch_id, p.paid, p.amount_paid, p.updated_at, p.receipt_name
  from public.healbite_admin_payments p
  where p.payment_month = p_month
  order by p.branch_id;
end;
$$;

create or replace function public.set_healbite_admin_payment_amount(
  p_password text,
  p_branch text,
  p_month text,
  p_amount numeric
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_password <> 'admin2026' then raise exception 'Invalid admin password'; end if;
  insert into public.healbite_admin_payments (branch_id, payment_month, paid, amount_paid, updated_at)
  values (p_branch, p_month, false, greatest(0, coalesce(p_amount,0)), now())
  on conflict (branch_id, payment_month) do update set
    amount_paid = excluded.amount_paid,
    updated_at = now();
end;
$$;

create or replace function public.set_healbite_admin_receipt(
  p_password text,
  p_branch text,
  p_month text,
  p_filename text,
  p_mime text,
  p_data text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_password <> 'admin2026' then raise exception 'Invalid admin password'; end if;
  insert into public.healbite_admin_payments (
    branch_id, payment_month, paid, receipt_name, receipt_mime, receipt_data, updated_at
  ) values (
    p_branch, p_month, false, left(p_filename, 180), p_mime, p_data, now()
  )
  on conflict (branch_id, payment_month) do update set
    receipt_name = excluded.receipt_name,
    receipt_mime = excluded.receipt_mime,
    receipt_data = excluded.receipt_data,
    updated_at = now();
end;
$$;

create or replace function public.get_healbite_admin_receipt(
  p_password text,
  p_branch text,
  p_month text
)
returns table(receipt_name text, receipt_mime text, receipt_data text)
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_password <> 'admin2026' then raise exception 'Invalid admin password'; end if;
  return query
  select p.receipt_name, p.receipt_mime, p.receipt_data
  from public.healbite_admin_payments p
  where p.branch_id = p_branch and p.payment_month = p_month;
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
revoke all on function public.set_healbite_admin_receipt(text,text,text,text,text,text) from public;
revoke all on function public.get_healbite_admin_receipt(text,text,text) from public;
revoke all on function public.set_healbite_admin_payment_amount(text,text,text,numeric) from public;
grant execute on function public.get_healbite_admin_payments(text,text) to anon, authenticated;
grant execute on function public.set_healbite_admin_payment(text,text,text,boolean) to anon, authenticated;
grant execute on function public.set_healbite_admin_receipt(text,text,text,text,text,text) to anon, authenticated;
grant execute on function public.get_healbite_admin_receipt(text,text,text) to anon, authenticated;
grant execute on function public.set_healbite_admin_payment_amount(text,text,text,numeric) to anon, authenticated;
