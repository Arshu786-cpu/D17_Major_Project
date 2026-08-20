/*
# EAIOS Application Tables

1. Purpose
   Creates the working data tables for the Enterprise AI Operating System:
   documents, conversations, messages, GitHub repos, reports, agent execution
   logs, audit logs, analytics events, and search logs. All tables are
   org-scoped and owner-aware so RLS can enforce organization isolation and
   role-based access.

2. New Tables
   - `documents` — uploaded enterprise knowledge files
   - `document_chunks` — mirror of vector payloads for citation + ACL checks
   - `conversations` — chat sessions between a user and the Main Agent
   - `messages` — individual messages in a conversation
   - `github_repos` — connected GitHub repositories
   - `reports` — AI-generated reports
   - `agent_executions` — execution log for the Main Agent + specialist agents
   - `audit_logs` — security audit trail
   - `analytics_events` — product usage events
   - `search_logs` — semantic search queries + result counts

3. Security
   - RLS enabled on every table with org-scoped CRUD policies.
   - Members of an org can read org-scoped data; only the owner (or admin) can
     update/delete. Audit logs and analytics events are insert-only.
*/

-- Enums
do $$ begin
  if not exists (select 1 from pg_type where typname = 'doc_status') then
    create type doc_status as enum ('processing', 'available', 'failed');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'doc_visibility') then
    create type doc_visibility as enum ('private', 'org', 'shared');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'execution_status') then
    create type execution_status as enum ('running', 'success', 'failed');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'report_format') then
    create type report_format as enum ('pdf', 'docx', 'markdown');
  end if;
end $$;

-- Helper: is the current user an admin in a given org?
create or replace function public.is_org_admin(p_org_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from profiles p
    where p.id = auth.uid() and p.org_id = p_org_id and p.role = 'admin'
  );
$$;

-- documents
create table if not exists documents (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  title text not null,
  type text not null,
  storage_path text not null,
  status doc_status not null default 'processing',
  visibility doc_visibility not null default 'org',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table documents enable row level security;

-- document_chunks
create table if not exists document_chunks (
  id uuid primary key default gen_random_uuid(),
  doc_id uuid not null references documents(id) on delete cascade,
  content text not null,
  chunk_index int not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table document_chunks enable row level security;

-- conversations
create table if not exists conversations (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  title text not null default 'New Conversation',
  created_at timestamptz not null default now()
);
alter table conversations enable row level security;

-- messages
create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations(id) on delete cascade,
  role text not null,
  content text not null,
  agent text,
  sources jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);
alter table messages enable row level security;

-- github_repos
create table if not exists github_repos (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  repo_owner text not null,
  repo_name text not null,
  token_ref text,
  last_synced_at timestamptz,
  created_at timestamptz not null default now()
);
alter table github_repos enable row level security;

-- reports
create table if not exists reports (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  type text not null,
  title text not null,
  format report_format not null default 'markdown',
  storage_path text,
  created_at timestamptz not null default now()
);
alter table reports enable row level security;

-- agent_executions
create table if not exists agent_executions (
  id uuid primary key default gen_random_uuid(),
  execution_id text not null,
  org_id uuid not null references organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  main_agent_status execution_status not null default 'running',
  specialist_agent text,
  tools_used text[] not null default '{}',
  status execution_status not null default 'running',
  duration_ms int,
  source_count int,
  created_at timestamptz not null default now()
);
alter table agent_executions enable row level security;

-- audit_logs
create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  org_id uuid references organizations(id) on delete set null,
  user_id uuid references auth.users(id) on delete set null,
  action text not null,
  resource text,
  ip text,
  created_at timestamptz not null default now()
);
alter table audit_logs enable row level security;

-- analytics_events
create table if not exists analytics_events (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table analytics_events enable row level security;

-- search_logs
create table if not exists search_logs (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  query text not null,
  result_count int not null default 0,
  created_at timestamptz not null default now()
);
alter table search_logs enable row level security;

-- ============ POLICIES ============

-- documents
drop policy if exists "doc_select_org" on documents;
create policy "doc_select_org"
  on documents for select to authenticated
  using (
    org_id in (select p.org_id from profiles p where p.id = auth.uid())
    and (visibility = 'org' or owner_id = auth.uid() or public.is_org_admin(org_id))
  );

drop policy if exists "doc_insert_org" on documents;
create policy "doc_insert_org"
  on documents for insert to authenticated
  with check (
    org_id in (select p.org_id from profiles p where p.id = auth.uid())
  );

drop policy if exists "doc_update_owner_admin" on documents;
create policy "doc_update_owner_admin"
  on documents for update to authenticated
  using (owner_id = auth.uid() or public.is_org_admin(org_id))
  with check (owner_id = auth.uid() or public.is_org_admin(org_id));

drop policy if exists "doc_delete_owner_admin" on documents;
create policy "doc_delete_owner_admin"
  on documents for delete to authenticated
  using (owner_id = auth.uid() or public.is_org_admin(org_id));

-- document_chunks
drop policy if exists "chunk_select_org" on document_chunks;
create policy "chunk_select_org"
  on document_chunks for select to authenticated
  using (
    exists (
      select 1 from documents d
      where d.id = document_chunks.doc_id
      and d.org_id in (select p.org_id from profiles p where p.id = auth.uid())
      and (d.visibility = 'org' or d.owner_id = auth.uid() or public.is_org_admin(d.org_id))
    )
  );

drop policy if exists "chunk_insert_doc_owner" on document_chunks;
create policy "chunk_insert_doc_owner"
  on document_chunks for insert to authenticated
  with check (
    exists (
      select 1 from documents d
      where d.id = document_chunks.doc_id
      and d.org_id in (select p.org_id from profiles p where p.id = auth.uid())
      and (d.owner_id = auth.uid() or public.is_org_admin(d.org_id))
    )
  );

drop policy if exists "chunk_update_doc_owner" on document_chunks;
create policy "chunk_update_doc_owner"
  on document_chunks for update to authenticated
  using (
    exists (
      select 1 from documents d
      where d.id = document_chunks.doc_id
      and (d.owner_id = auth.uid() or public.is_org_admin(d.org_id))
    )
  )
  with check (
    exists (
      select 1 from documents d
      where d.id = document_chunks.doc_id
      and (d.owner_id = auth.uid() or public.is_org_admin(d.org_id))
    )
  );

drop policy if exists "chunk_delete_doc_owner" on document_chunks;
create policy "chunk_delete_doc_owner"
  on document_chunks for delete to authenticated
  using (
    exists (
      select 1 from documents d
      where d.id = document_chunks.doc_id
      and (d.owner_id = auth.uid() or public.is_org_admin(d.org_id))
    )
  );

-- conversations
drop policy if exists "conv_select_owner_admin" on conversations;
create policy "conv_select_owner_admin"
  on conversations for select to authenticated
  using (user_id = auth.uid() or public.is_org_admin(org_id));

drop policy if exists "conv_insert_self" on conversations;
create policy "conv_insert_self"
  on conversations for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "conv_update_owner_admin" on conversations;
create policy "conv_update_owner_admin"
  on conversations for update to authenticated
  using (user_id = auth.uid() or public.is_org_admin(org_id))
  with check (user_id = auth.uid() or public.is_org_admin(org_id));

drop policy if exists "conv_delete_owner_admin" on conversations;
create policy "conv_delete_owner_admin"
  on conversations for delete to authenticated
  using (user_id = auth.uid() or public.is_org_admin(org_id));

-- messages
drop policy if exists "msg_select_owner_admin" on messages;
create policy "msg_select_owner_admin"
  on messages for select to authenticated
  using (
    exists (
      select 1 from conversations c
      where c.id = messages.conversation_id
      and (c.user_id = auth.uid() or public.is_org_admin(c.org_id))
    )
  );

drop policy if exists "msg_insert_conv_owner" on messages;
create policy "msg_insert_conv_owner"
  on messages for insert to authenticated
  with check (
    exists (
      select 1 from conversations c
      where c.id = messages.conversation_id
      and (c.user_id = auth.uid() or public.is_org_admin(c.org_id))
    )
  );

drop policy if exists "msg_update_conv_owner" on messages;
create policy "msg_update_conv_owner"
  on messages for update to authenticated
  using (
    exists (
      select 1 from conversations c
      where c.id = messages.conversation_id
      and c.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from conversations c
      where c.id = messages.conversation_id
      and c.user_id = auth.uid()
    )
  );

drop policy if exists "msg_delete_conv_owner" on messages;
create policy "msg_delete_conv_owner"
  on messages for delete to authenticated
  using (
    exists (
      select 1 from conversations c
      where c.id = messages.conversation_id
      and c.user_id = auth.uid()
    )
  );

-- github_repos
drop policy if exists "repo_select_owner_admin" on github_repos;
create policy "repo_select_owner_admin"
  on github_repos for select to authenticated
  using (owner_id = auth.uid() or public.is_org_admin(org_id));

drop policy if exists "repo_insert_self" on github_repos;
create policy "repo_insert_self"
  on github_repos for insert to authenticated
  with check (owner_id = auth.uid());

drop policy if exists "repo_update_owner_admin" on github_repos;
create policy "repo_update_owner_admin"
  on github_repos for update to authenticated
  using (owner_id = auth.uid() or public.is_org_admin(org_id))
  with check (owner_id = auth.uid() or public.is_org_admin(org_id));

drop policy if exists "repo_delete_owner_admin" on github_repos;
create policy "repo_delete_owner_admin"
  on github_repos for delete to authenticated
  using (owner_id = auth.uid() or public.is_org_admin(org_id));

-- reports
drop policy if exists "report_select_owner_admin" on reports;
create policy "report_select_owner_admin"
  on reports for select to authenticated
  using (owner_id = auth.uid() or public.is_org_admin(org_id));

drop policy if exists "report_insert_self" on reports;
create policy "report_insert_self"
  on reports for insert to authenticated
  with check (owner_id = auth.uid());

drop policy if exists "report_update_owner_admin" on reports;
create policy "report_update_owner_admin"
  on reports for update to authenticated
  using (owner_id = auth.uid() or public.is_org_admin(org_id))
  with check (owner_id = auth.uid() or public.is_org_admin(org_id));

drop policy if exists "report_delete_owner_admin" on reports;
create policy "report_delete_owner_admin"
  on reports for delete to authenticated
  using (owner_id = auth.uid() or public.is_org_admin(org_id));

-- agent_executions
drop policy if exists "exec_select_owner_admin" on agent_executions;
create policy "exec_select_owner_admin"
  on agent_executions for select to authenticated
  using (user_id = auth.uid() or public.is_org_admin(org_id));

drop policy if exists "exec_insert_self" on agent_executions;
create policy "exec_insert_self"
  on agent_executions for insert to authenticated
  with check (user_id = auth.uid());

-- audit_logs
drop policy if exists "audit_select_admin" on audit_logs;
create policy "audit_select_admin"
  on audit_logs for select to authenticated
  using (public.is_org_admin(org_id) or user_id = auth.uid());

drop policy if exists "audit_insert_self" on audit_logs;
create policy "audit_insert_self"
  on audit_logs for insert to authenticated
  with check (user_id = auth.uid());

-- analytics_events
drop policy if exists "analytics_select_org" on analytics_events;
create policy "analytics_select_org"
  on analytics_events for select to authenticated
  using (
    org_id in (select p.org_id from profiles p where p.id = auth.uid())
  );

drop policy if exists "analytics_insert_self" on analytics_events;
create policy "analytics_insert_self"
  on analytics_events for insert to authenticated
  with check (user_id = auth.uid());

-- search_logs
drop policy if exists "search_select_owner_admin" on search_logs;
create policy "search_select_owner_admin"
  on search_logs for select to authenticated
  using (user_id = auth.uid() or public.is_org_admin(org_id));

drop policy if exists "search_insert_self" on search_logs;
create policy "search_insert_self"
  on search_logs for insert to authenticated
  with check (user_id = auth.uid());

-- Indexes
create index if not exists idx_documents_org on documents(org_id);
create index if not exists idx_documents_owner on documents(owner_id);
create index if not exists idx_chunks_doc on document_chunks(doc_id);
create index if not exists idx_conversations_user on conversations(user_id);
create index if not exists idx_messages_conversation on messages(conversation_id);
create index if not exists idx_repos_org on github_repos(org_id);
create index if not exists idx_reports_org on reports(org_id);
create index if not exists idx_executions_org on agent_executions(org_id);
create index if not exists idx_executions_user on agent_executions(user_id);
create index if not exists idx_audit_org on audit_logs(org_id);
create index if not exists idx_analytics_org on analytics_events(org_id);
create index if not exists idx_search_org on search_logs(org_id);
