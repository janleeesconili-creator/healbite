create table if not exists public.healbite_daily_metrics (
  branch_id text not null references public.healbite_branches(id) on delete cascade,
  metric_date date not null,
  page_views numeric not null default 0,
  impressions numeric not null default 0,
  hot_leads numeric not null default 0,
  booked numeric not null default 0,
  total_messages numeric not null default 0,
  ads_spend numeric not null default 0,
  cash_sales numeric not null default 0,
  accrual_sales numeric not null default 0,
  updated_at timestamptz not null default now(),
  primary key (branch_id, metric_date)
);

alter table public.healbite_daily_metrics
  add column if not exists impressions numeric not null default 0;

alter table public.healbite_daily_metrics enable row level security;
revoke all on public.healbite_daily_metrics from anon, authenticated;

create or replace function public.get_healbite_daily_metrics(
  p_pin text,
  p_branch text,
  p_month text
)
returns setof public.healbite_daily_metrics
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_pin <> '2026' then raise exception 'Invalid PIN'; end if;
  return query
  select * from public.healbite_daily_metrics d
  where d.branch_id = p_branch
    and case when length(p_month) = 4
      then to_char(d.metric_date, 'YYYY') = p_month
      else to_char(d.metric_date, 'YYYY-MM') = p_month
    end
  order by d.metric_date desc;
end;
$$;

create or replace function public.upsert_healbite_daily_metrics(
  p_pin text,
  p_branch text,
  p_date date,
  p_data jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_pin <> '2026' then raise exception 'Invalid PIN'; end if;
  insert into public.healbite_daily_metrics (
    branch_id, metric_date, page_views, impressions, hot_leads, booked,
    total_messages, ads_spend, cash_sales, accrual_sales, updated_at
  ) values (
    p_branch, p_date,
    greatest(0, coalesce((p_data->>'pageViews')::numeric,0)),
    greatest(0, coalesce((p_data->>'impressions')::numeric,0)),
    greatest(0, coalesce((p_data->>'hotLeads')::numeric,0)),
    greatest(0, coalesce((p_data->>'booked')::numeric,0)),
    greatest(0, coalesce((p_data->>'totalMessages')::numeric,0)),
    greatest(0, coalesce((p_data->>'adsSpend')::numeric,0)),
    greatest(0, coalesce((p_data->>'cashSales')::numeric,0)),
    greatest(0, coalesce((p_data->>'accrualSales')::numeric,0)), now()
  )
  on conflict (branch_id, metric_date) do update set
    page_views=excluded.page_views, impressions=excluded.impressions,
    hot_leads=excluded.hot_leads,
    booked=excluded.booked, total_messages=excluded.total_messages,
    ads_spend=excluded.ads_spend, cash_sales=excluded.cash_sales,
    accrual_sales=excluded.accrual_sales,
    updated_at=now();
end;
$$;

revoke all on function public.get_healbite_daily_metrics(text,text,text) from public;
revoke all on function public.upsert_healbite_daily_metrics(text,text,date,jsonb) from public;
grant execute on function public.get_healbite_daily_metrics(text,text,text) to anon, authenticated;
grant execute on function public.upsert_healbite_daily_metrics(text,text,date,jsonb) to anon, authenticated;
