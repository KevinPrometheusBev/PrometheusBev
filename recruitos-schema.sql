-- Prometheus RECRUIT
-- Designed for PostgreSQL / Supabase-style apps.

create table users (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null unique,
  role text not null check (role in ('admin', 'recruiter', 'client_viewer')),
  status text not null default 'active' check (status in ('active', 'invited', 'disabled')),
  last_login_at timestamptz,
  created_at timestamptz not null default now()
);

create table clients (
  id uuid primary key default gen_random_uuid(),
  company_name text not null,
  industry text,
  primary_contact_name text,
  primary_contact_email text,
  urgency text not null default 'medium' check (urgency in ('low', 'medium', 'high')),
  contract_terms text,
  projected_fees numeric(12, 2) not null default 0,
  owner_id uuid references users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table candidates (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  email text not null unique,
  phone text,
  location text,
  current_title text,
  status text not null default 'available' check (status in ('available', 'interviewing', 'placed', 'archived')),
  source text,
  skills text[] not null default '{}',
  owner_id uuid references users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table searches (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references clients(id) on delete cascade,
  role_title text not null,
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  salary_min numeric(12, 2),
  salary_max numeric(12, 2),
  status text not null default 'open' check (status in ('open', 'paused', 'filled', 'closed')),
  owner_id uuid references users(id),
  opened_at timestamptz not null default now(),
  closed_at timestamptz
);

create table pipeline_items (
  id uuid primary key default gen_random_uuid(),
  candidate_id uuid not null references candidates(id) on delete cascade,
  search_id uuid not null references searches(id) on delete cascade,
  stage text not null default 'sourced' check (stage in ('sourced', 'screening', 'client_review', 'interview', 'offer', 'placed', 'rejected')),
  projected_fee numeric(12, 2) not null default 0,
  next_step text,
  owner_id uuid references users(id),
  updated_at timestamptz not null default now(),
  unique(candidate_id, search_id)
);

create table notes (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null check (entity_type in ('candidate', 'client', 'search', 'pipeline_item')),
  entity_id uuid not null,
  author_id uuid references users(id),
  body text not null,
  created_at timestamptz not null default now()
);

create index candidates_search_idx on candidates using gin (
  to_tsvector('english', full_name || ' ' || coalesce(current_title, '') || ' ' || array_to_string(skills, ' '))
);

create index clients_company_idx on clients(company_name);
create index searches_client_idx on searches(client_id);
create index pipeline_stage_idx on pipeline_items(stage);
create index notes_entity_idx on notes(entity_type, entity_id);
