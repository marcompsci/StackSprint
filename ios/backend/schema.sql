-- Run once in a NEW Supabase project's SQL editor, or via migrations.
begin;
create table public.progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id text not null check (length(lesson_id) between 1 and 120),
  completed_at timestamptz not null default now(),
  primary key(user_id, lesson_id)
);
alter table public.progress enable row level security;
revoke all on public.progress from anon, authenticated;
grant select, insert on public.progress to authenticated;
create policy "Read own progress" on public.progress for select to authenticated using ((select auth.uid()) = user_id);
create policy "Insert own progress" on public.progress for insert to authenticated with check ((select auth.uid()) = user_id);

-- No arbitrary user ID parameter: only the authenticated caller can be deleted.
create function public.delete_my_account() returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  delete from auth.users where id = auth.uid();
end;
$$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
commit;
