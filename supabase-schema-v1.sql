create table if not exists public.user_rejection_state (
  user_id uuid primary key references auth.users (id) on delete cascade,
  email text,
  active_entries jsonb not null default '[]'::jsonb,
  jars jsonb not null default '[]'::jsonb,
  round_started_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.user_rejection_state enable row level security;

create or replace function public.touch_user_rejection_state()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists trg_touch_user_rejection_state on public.user_rejection_state;

create trigger trg_touch_user_rejection_state
before update on public.user_rejection_state
for each row
execute function public.touch_user_rejection_state();

drop policy if exists "Users can read own rejection state" on public.user_rejection_state;
create policy "Users can read own rejection state"
on public.user_rejection_state
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own rejection state" on public.user_rejection_state;
create policy "Users can insert own rejection state"
on public.user_rejection_state
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own rejection state" on public.user_rejection_state;
create policy "Users can update own rejection state"
on public.user_rejection_state
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
