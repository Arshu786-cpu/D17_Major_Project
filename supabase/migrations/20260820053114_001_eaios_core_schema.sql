/*
# EAIOS Core Schema — Organizations, Profiles, Roles

1. Purpose
   Establishes the multi-tenant foundation of the Enterprise AI Operating System.
   Organizations isolate data between companies. Each user belongs to one
   organization and has a role (admin / manager / employee) that controls what
   they can do across the platform.

2. New Tables
   - `organizations` — top-level tenant boundary (id, name, slug, created_at)
   - `profiles` — extends Supabase auth.users with org membership + role
     (id FK auth.users, org_id FK organizations, role enum, full_name, created_at)
   NOTE: profiles.id IS the auth.users id (1:1). Policies compare against id,
   not a separate user_id column.

3. Enums
   - `user_role` : 'admin' | 'manager' | 'employee'

4. Security
   - RLS enabled on both tables.
   - `organizations`: members (users in the same org) can SELECT; only admins
     can INSERT/UPDATE/DELETE.
   - `profiles`: a user can read all profiles in their own org (needed for the
     Agent Center, activity feeds, admin views) and always their own profile;
     can update only their own profile row; inserts are handled by a trigger on
     auth.users so we provide an authenticated INSERT policy for safety; deletes
     are admin-only within the org.

5. Trigger
   - `handle_new_user` trigger: when a new row is added to auth.users, insert a
     matching row into `profiles`. The org_id defaults to NULL and role to
     'employee' until an admin assigns the user to an organization. This keeps
     signup working without a separate profile-creation step in the frontend.
*/

-- Extensions
create extension if not exists "pgcrypto";

-- Enums
do $$ begin
  if not exists (select 1 from pg_type where typname = 'user_role') then
    create type user_role as enum ('admin', 'manager', 'employee');
  end if;
end $$;

-- Tables (created before any policies that reference them)
create table if not exists organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  created_at timestamptz not null default now()
);

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  org_id uuid references organizations(id) on delete set null,
  role user_role not null default 'employee',
  full_name text,
  created_at timestamptz not null default now()
);

-- RLS
alter table organizations enable row level security;
alter table profiles enable row level security;

-- Organization policies
drop policy if exists "org_select_members" on organizations;
create policy "org_select_members"
  on organizations for select
  to authenticated
  using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.org_id = organizations.id
    )
  );

drop policy if exists "org_insert_admin" on organizations;
create policy "org_insert_admin"
  on organizations for insert
  to authenticated
  with check (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

drop policy if exists "org_update_admin" on organizations;
create policy "org_update_admin"
  on organizations for update
  to authenticated
  using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role = 'admin' and p.org_id = organizations.id
    )
  )
  with check (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role = 'admin' and p.org_id = organizations.id
    )
  );

drop policy if exists "org_delete_admin" on organizations;
create policy "org_delete_admin"
  on organizations for delete
  to authenticated
  using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role = 'admin' and p.org_id = organizations.id
    )
  );

-- Profile policies
drop policy if exists "profile_select_org" on profiles;
create policy "profile_select_org"
  on profiles for select
  to authenticated
  using (
    id = auth.uid()
    or (
      org_id is not null
      and exists (
        select 1 from profiles me
        where me.id = auth.uid() and me.org_id = profiles.org_id
      )
    )
  );

drop policy if exists "profile_update_self" on profiles;
create policy "profile_update_self"
  on profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

drop policy if exists "profile_insert_self" on profiles;
create policy "profile_insert_self"
  on profiles for insert
  to authenticated
  with check (id = auth.uid());

drop policy if exists "profile_delete_admin" on profiles;
create policy "profile_delete_admin"
  on profiles for delete
  to authenticated
  using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role = 'admin' and p.org_id = profiles.org_id
    )
  );

-- Trigger: auto-create a profile row when a new auth.user is created
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role, full_name)
  values (new.id, 'employee', coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
