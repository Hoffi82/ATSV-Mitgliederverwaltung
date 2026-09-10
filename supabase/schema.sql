-- ATSV Mitgliederverwaltung – Datenbankschema
-- Die produktive Migration wurde in Supabase ausgeführt.
-- Personenbezogene Daten gehören nicht ins Git-Repository.

create extension if not exists pgcrypto;

create sequence if not exists public.member_number_seq start 1;

create table public.staff_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'staff' check (role in ('admin','staff')),
  created_at timestamptz not null default now()
);

create table public.members (
  id uuid primary key default gen_random_uuid(),
  member_number text not null unique default ('ATSV-' || lpad(nextval('public.member_number_seq')::text, 6, '0')),
  first_name text not null,
  last_name text not null,
  birth_date date not null,
  birth_place text,
  nationality text,
  gender text,
  street text,
  postal_code text,
  city text,
  phone text,
  email text,
  department text not null,
  entry_date date not null default current_date,
  status text not null default 'aktiv' check (status in ('aktiv','inaktiv')),
  guardian_name text,
  guardian_phone text,
  guardian_email text,
  additional_contact text,
  application_id uuid,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.admission_applications (
  id uuid primary key default gen_random_uuid(),
  application_number text not null unique default ('ANTRAG-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,8))),
  first_name text not null,
  last_name text not null,
  birth_date date not null,
  birth_place text,
  nationality text,
  gender text,
  street text,
  postal_code text,
  city text,
  phone text,
  email text,
  department text not null,
  desired_entry_date date,
  guardian_name text,
  guardian_phone text,
  guardian_email text,
  application_type text not null default 'normal' check (application_type in ('normal','auslaendische_kinder')),
  evidence_notes text,
  privacy_consent boolean not null default false,
  status text not null default 'neu' check (status in ('neu','in_pruefung','angenommen','abgelehnt')),
  rejection_reason text,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  accepted_member_id uuid references public.members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.members
  add constraint members_application_id_fkey
  foreign key (application_id) references public.admission_applications(id) on delete set null;

create table public.member_documents (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  file_name text not null,
  storage_path text not null,
  document_type text,
  uploaded_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.contributions (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  year integer not null check (year between 2000 and 2100),
  amount numeric(10,2) not null check (amount >= 0),
  status text not null default 'offen' check (status in ('offen','bezahlt','gemahnt','storniert')),
  payment_method text,
  paid_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(member_id, year)
);

create table public.member_notes (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  note text not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.activity_log (
  id bigint generated always as identity primary key,
  member_id uuid references public.members(id) on delete cascade,
  application_id uuid references public.admission_applications(id) on delete cascade,
  action text not null,
  details text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index members_name_idx on public.members(last_name, first_name);
create index members_status_idx on public.members(status);
create index members_department_idx on public.members(department);
create index admission_status_idx on public.admission_applications(status);
create index admission_created_idx on public.admission_applications(created_at desc);
create index documents_member_idx on public.member_documents(member_id);
create index contributions_member_idx on public.contributions(member_id);
create index notes_member_idx on public.member_notes(member_id);
create index activity_member_idx on public.activity_log(member_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger members_set_updated_at before update on public.members
for each row execute function public.set_updated_at();
create trigger applications_set_updated_at before update on public.admission_applications
for each row execute function public.set_updated_at();
create trigger contributions_set_updated_at before update on public.contributions
for each row execute function public.set_updated_at();

create or replace function public.accept_admission_application()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_member_id uuid;
begin
  if new.status = 'angenommen' and (old.status is distinct from new.status) and new.accepted_member_id is null then
    insert into public.members (
      first_name,last_name,birth_date,birth_place,nationality,gender,
      street,postal_code,city,phone,email,department,entry_date,
      guardian_name,guardian_phone,guardian_email,application_id,notes
    ) values (
      new.first_name,new.last_name,new.birth_date,new.birth_place,new.nationality,new.gender,
      new.street,new.postal_code,new.city,new.phone,new.email,new.department,
      coalesce(new.desired_entry_date,current_date),new.guardian_name,new.guardian_phone,new.guardian_email,
      new.id,new.evidence_notes
    ) returning id into new_member_id;

    new.accepted_member_id = new_member_id;
    new.reviewed_at = coalesce(new.reviewed_at, now());

    insert into public.activity_log(member_id, application_id, action, details, created_by)
    values (new_member_id, new.id, 'antrag_angenommen', 'Mitglied automatisch aus Aufnahmeantrag angelegt.', new.reviewed_by);
  end if;
  return new;
end;
$$;

create trigger application_accepts_member
before update on public.admission_applications
for each row execute function public.accept_admission_application();

alter table public.staff_users enable row level security;
alter table public.members enable row level security;
alter table public.admission_applications enable row level security;
alter table public.member_documents enable row level security;
alter table public.contributions enable row level security;
alter table public.member_notes enable row level security;
alter table public.activity_log enable row level security;

create policy staff_users_self_read on public.staff_users
for select to authenticated using (user_id = auth.uid());

create policy staff_members_all on public.members
for all to authenticated using (exists (select 1 from public.staff_users s where s.user_id = auth.uid()))
with check (exists (select 1 from public.staff_users s where s.user_id = auth.uid()));

create policy staff_applications_all on public.admission_applications
for all to authenticated using (exists (select 1 from public.staff_users s where s.user_id = auth.uid()))
with check (exists (select 1 from public.staff_users s where s.user_id = auth.uid()));

create policy public_application_insert on public.admission_applications
for insert to anon, authenticated
with check (privacy_consent = true);

create policy staff_documents_all on public.member_documents
for all to authenticated using (exists (select 1 from public.staff_users s where s.user_id = auth.uid()))
with check (exists (select 1 from public.staff_users s where s.user_id = auth.uid()));

create policy staff_contributions_all on public.contributions
for all to authenticated using (exists (select 1 from public.staff_users s where s.user_id = auth.uid()))
with check (exists (select 1 from public.staff_users s where s.user_id = auth.uid()));

create policy staff_notes_all on public.member_notes
for all to authenticated using (exists (select 1 from public.staff_users s where s.user_id = auth.uid()))
with check (exists (select 1 from public.staff_users s where s.user_id = auth.uid()));

create policy staff_activity_read on public.activity_log
for select to authenticated using (exists (select 1 from public.staff_users s where s.user_id = auth.uid()));

create policy staff_activity_insert on public.activity_log
for insert to authenticated with check (exists (select 1 from public.staff_users s where s.user_id = auth.uid()));

revoke execute on function public.accept_admission_application() from public, anon, authenticated;
revoke execute on function public.set_updated_at() from public, anon, authenticated;
