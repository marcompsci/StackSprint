-- ONLY for a fresh disposable PostgreSQL database. Not a Supabase project.
\set ON_ERROR_STOP on
create role anon nologin;
create role authenticated nologin;
create schema auth;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
grant usage on schema auth to authenticated, anon;
grant execute on function auth.uid() to authenticated, anon;
\ir schema.sql
insert into auth.users values ('00000000-0000-0000-0000-000000000001'), ('00000000-0000-0000-0000-000000000002');
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
insert into public.progress(user_id, lesson_id) values (auth.uid(), 'html');
do $$ begin
  begin
    insert into public.progress(user_id, lesson_id) values ('00000000-0000-0000-0000-000000000002', 'css');
    raise exception 'FAIL: cross-user insertion allowed';
  exception when insufficient_privilege then null;
  end;
end $$;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
do $$ begin if (select count(*) from public.progress) <> 0 then raise exception 'FAIL: cross-user read'; end if; end $$;
insert into public.progress(user_id, lesson_id) values (auth.uid(), 'css');
select public.delete_my_account();
reset role;
do $$ begin
  if (select count(*) from auth.users) <> 1 then raise exception 'FAIL: account deletion'; end if;
  if (select count(*) from public.progress) <> 1 then raise exception 'FAIL: cascade deletion'; end if;
end $$;
set role anon;
do $$ begin
  begin
    perform * from public.progress;
    raise exception 'FAIL: anonymous read allowed';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
select 'PASS: owner access, cross-user isolation, anonymous denial, account deletion, cascade cleanup';
