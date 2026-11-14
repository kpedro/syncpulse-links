-- SyncPulse Links (link-in-bio editável). Tabelas novas, prefixo syncpulse_links_. Não altera nada existente.

create table if not exists public.syncpulse_links_admins (
  email text primary key check (email = lower(email)),
  created_at timestamptz not null default now()
);
comment on table public.syncpulse_links_admins is 'SyncPulse Links — e-mails autorizados a editar a página de links.';

create or replace function public.syncpulse_links_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.syncpulse_links_admins a
    where a.email = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function public.syncpulse_links_is_admin() from public;
grant execute on function public.syncpulse_links_is_admin() to anon, authenticated;

create or replace function public.syncpulse_links_touch_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create table if not exists public.syncpulse_links_profile (
  id smallint primary key default 1 check (id = 1),
  name text not null default 'Kadson Pedro' check (char_length(name) between 1 and 80),
  bio text check (bio is null or char_length(bio) <= 400),
  handle text check (handle is null or char_length(handle) <= 60),
  photo_url text check (photo_url is null or photo_url ~* '^https://'),
  bg_color text not null default '#0b1b46' check (bg_color ~ '^#[0-9a-fA-F]{6}$'),
  bg_color_2 text not null default '#1e3a8a' check (bg_color_2 ~ '^#[0-9a-fA-F]{6}$'),
  text_color text not null default '#ffffff' check (text_color ~ '^#[0-9a-fA-F]{6}$'),
  button_bg_color text not null default '#2563eb' check (button_bg_color ~ '^#[0-9a-fA-F]{6}$'),
  button_text_color text not null default '#ffffff' check (button_text_color ~ '^#[0-9a-fA-F]{6}$'),
  page_title text check (page_title is null or char_length(page_title) <= 90),
  updated_at timestamptz not null default now()
);
comment on table public.syncpulse_links_profile is 'SyncPulse Links — perfil (linha única) exibido no topo de links.syncpulse.com.br.';

create table if not exists public.syncpulse_links_sections (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 60),
  position integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.syncpulse_links_sections is 'SyncPulse Links — seções (grupos de botões).';

create table if not exists public.syncpulse_links_items (
  id uuid primary key default gen_random_uuid(),
  section_id uuid not null references public.syncpulse_links_sections(id) on delete cascade,
  label text not null check (char_length(label) between 1 and 80),
  url text not null check (char_length(url) <= 2000 and url ~* '^(https?://|mailto:|tel:)'),
  bg_color text check (bg_color is null or bg_color ~ '^#[0-9a-fA-F]{6}$'),
  text_color text check (text_color is null or text_color ~ '^#[0-9a-fA-F]{6}$'),
  position integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.syncpulse_links_items is 'SyncPulse Links — botões/links de cada seção.';
create index if not exists syncpulse_links_items_section_idx on public.syncpulse_links_items (section_id, position);

create trigger syncpulse_links_profile_touch before update on public.syncpulse_links_profile
  for each row execute function public.syncpulse_links_touch_updated_at();
create trigger syncpulse_links_sections_touch before update on public.syncpulse_links_sections
  for each row execute function public.syncpulse_links_touch_updated_at();
create trigger syncpulse_links_items_touch before update on public.syncpulse_links_items
  for each row execute function public.syncpulse_links_touch_updated_at();

-- RLS
alter table public.syncpulse_links_admins enable row level security;
alter table public.syncpulse_links_profile enable row level security;
alter table public.syncpulse_links_sections enable row level security;
alter table public.syncpulse_links_items enable row level security;

-- Privilégios explícitos: anon só lê; escrita só via authenticated + políticas de admin.
revoke all on public.syncpulse_links_admins, public.syncpulse_links_profile,
  public.syncpulse_links_sections, public.syncpulse_links_items from anon, authenticated;
grant select on public.syncpulse_links_profile, public.syncpulse_links_sections,
  public.syncpulse_links_items to anon, authenticated;
grant insert, update, delete on public.syncpulse_links_profile, public.syncpulse_links_sections,
  public.syncpulse_links_items to authenticated;
grant select on public.syncpulse_links_admins to authenticated;

create policy "syncpulse_links_admins_select_self_admin" on public.syncpulse_links_admins
  for select to authenticated using (public.syncpulse_links_is_admin());

create policy "syncpulse_links_profile_public_read" on public.syncpulse_links_profile
  for select to anon, authenticated using (true);
create policy "syncpulse_links_profile_admin_insert" on public.syncpulse_links_profile
  for insert to authenticated with check (public.syncpulse_links_is_admin());
create policy "syncpulse_links_profile_admin_update" on public.syncpulse_links_profile
  for update to authenticated using (public.syncpulse_links_is_admin()) with check (public.syncpulse_links_is_admin());
create policy "syncpulse_links_profile_admin_delete" on public.syncpulse_links_profile
  for delete to authenticated using (public.syncpulse_links_is_admin());

create policy "syncpulse_links_sections_public_read" on public.syncpulse_links_sections
  for select to anon, authenticated using (active or public.syncpulse_links_is_admin());
create policy "syncpulse_links_sections_admin_insert" on public.syncpulse_links_sections
  for insert to authenticated with check (public.syncpulse_links_is_admin());
create policy "syncpulse_links_sections_admin_update" on public.syncpulse_links_sections
  for update to authenticated using (public.syncpulse_links_is_admin()) with check (public.syncpulse_links_is_admin());
create policy "syncpulse_links_sections_admin_delete" on public.syncpulse_links_sections
  for delete to authenticated using (public.syncpulse_links_is_admin());

create policy "syncpulse_links_items_public_read" on public.syncpulse_links_items
  for select to anon, authenticated using (active or public.syncpulse_links_is_admin());
create policy "syncpulse_links_items_admin_insert" on public.syncpulse_links_items
  for insert to authenticated with check (public.syncpulse_links_is_admin());
create policy "syncpulse_links_items_admin_update" on public.syncpulse_links_items
  for update to authenticated using (public.syncpulse_links_is_admin()) with check (public.syncpulse_links_is_admin());
create policy "syncpulse_links_items_admin_delete" on public.syncpulse_links_items
  for delete to authenticated using (public.syncpulse_links_is_admin());

-- Storage: bucket público para a foto do perfil. Leitura pública pela URL; escrita só admin.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('syncpulse-links', 'syncpulse-links', true, 5242880,
        array['image/png','image/jpeg','image/webp','image/gif'])
on conflict (id) do nothing;

create policy "syncpulse_links_storage_admin_select" on storage.objects
  for select to authenticated using (bucket_id = 'syncpulse-links' and public.syncpulse_links_is_admin());
create policy "syncpulse_links_storage_admin_insert" on storage.objects
  for insert to authenticated with check (bucket_id = 'syncpulse-links' and public.syncpulse_links_is_admin());
create policy "syncpulse_links_storage_admin_update" on storage.objects
  for update to authenticated using (bucket_id = 'syncpulse-links' and public.syncpulse_links_is_admin())
  with check (bucket_id = 'syncpulse-links' and public.syncpulse_links_is_admin());
create policy "syncpulse_links_storage_admin_delete" on storage.objects
  for delete to authenticated using (bucket_id = 'syncpulse-links' and public.syncpulse_links_is_admin());

-- Seed (dados reais)
insert into public.syncpulse_links_admins (email) values ('kadson.pedro@gmail.com') on conflict do nothing;

insert into public.syncpulse_links_profile (id, name, bio, page_title)
values (1, 'Kadson Pedro', 'Fundador da SyncPulse', 'Kadson Pedro | SyncPulse')
on conflict (id) do nothing;

do $$
declare s_pf uuid; s_apps uuid; s_contato uuid;
begin
  if not exists (select 1 from public.syncpulse_links_sections) then
    insert into public.syncpulse_links_sections (title, position) values ('PedagoFlow', 0) returning id into s_pf;
    insert into public.syncpulse_links_sections (title, position) values ('Apps SyncPulse', 1) returning id into s_apps;
    insert into public.syncpulse_links_sections (title, position) values ('Contato', 2) returning id into s_contato;

    insert into public.syncpulse_links_items (section_id, label, url, bg_color, text_color, position) values
      (s_pf, 'PedagoFlow — app, WhatsApp e extensão', 'https://pedagoflow.syncpulse.com.br', '#2563eb', '#ffffff', 0),
      (s_apps, 'Caderno', 'https://caderno.syncpulse.com.br', '#ffffff', '#0b1b46', 0),
      (s_apps, 'Segundo Cérebro IA', 'https://portal.syncpulse.com.br', '#ffffff', '#0b1b46', 1),
      (s_apps, 'Mente em Construção', 'https://mente.syncpulse.com.br', '#ffffff', '#0b1b46', 2),
      (s_apps, 'Lume', 'https://lume.syncpulse.com.br', '#ffffff', '#0b1b46', 3),
      (s_apps, 'SyncPulse Fit', 'https://loja.syncpulse.com.br', '#ffffff', '#0b1b46', 4),
      (s_contato, 'WhatsApp', 'https://wa.me/5592994314016', '#25d366', '#0b1b46', 0),
      (s_contato, 'E-mail', 'mailto:contato@syncpulse.com.br', '#dbeafe', '#0b1b46', 1),
      (s_contato, 'Site', 'https://www.syncpulse.com.br', '#dbeafe', '#0b1b46', 2);
  end if;
end $$;
