-- TT SPENCE database schema. Run this in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (char_length(username) between 3 and 24),
  display_name text not null,
  bio text default '',
  avatar_url text,
  created_at timestamptz not null default now()
);
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null default '' check (char_length(content) <= 3000),
  image_url text,
  created_at timestamptz not null default now(),
  check (char_length(content) > 0 or image_url is not null)
);
create table if not exists public.likes (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(post_id,user_id)
);
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 1000),
  created_at timestamptz not null default now()
);
create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(follower_id,following_id),
  check(follower_id <> following_id)
);
create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 500),
  media_url text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 5000),
  created_at timestamptz not null default now(),
  read_at timestamptz,
  check(sender_id <> receiver_id)
);

-- Automatically create a profile when a new auth account is registered.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
declare
  base_name text;
  safe_username text;
begin
  base_name := coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email,'@',1), 'member');
  safe_username := lower(regexp_replace(coalesce(new.raw_user_meta_data->>'username', base_name), '[^a-zA-Z0-9_]', '', 'g'));
  if length(safe_username) < 3 then safe_username := 'member'; end if;
  safe_username := left(safe_username, 16) || '_' || left(replace(new.id::text,'-',''),6);
  insert into public.profiles(id, username, display_name)
  values(new.id, safe_username, base_name);
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.likes enable row level security;
alter table public.comments enable row level security;
alter table public.follows enable row level security;
alter table public.stories enable row level security;
alter table public.messages enable row level security;

create policy "Profiles are visible to signed-in members" on public.profiles for select to authenticated using (true);
create policy "Members update their own profile" on public.profiles for update to authenticated using (auth.uid()=id) with check (auth.uid()=id);
create policy "Signed-in members read posts" on public.posts for select to authenticated using (true);
create policy "Members create their own posts" on public.posts for insert to authenticated with check (auth.uid()=user_id);
create policy "Members edit their own posts" on public.posts for update to authenticated using (auth.uid()=user_id) with check (auth.uid()=user_id);
create policy "Members delete their own posts" on public.posts for delete to authenticated using (auth.uid()=user_id);
create policy "Likes visible to members" on public.likes for select to authenticated using (true);
create policy "Members like as themselves" on public.likes for insert to authenticated with check (auth.uid()=user_id);
create policy "Members remove own likes" on public.likes for delete to authenticated using (auth.uid()=user_id);
create policy "Comments visible to members" on public.comments for select to authenticated using (true);
create policy "Members comment as themselves" on public.comments for insert to authenticated with check (auth.uid()=user_id);
create policy "Members delete own comments" on public.comments for delete to authenticated using (auth.uid()=user_id);
create policy "Follows visible to members" on public.follows for select to authenticated using (true);
create policy "Members follow as themselves" on public.follows for insert to authenticated with check (auth.uid()=follower_id);
create policy "Members unfollow as themselves" on public.follows for delete to authenticated using (auth.uid()=follower_id);
create policy "Active stories visible to members" on public.stories for select to authenticated using (expires_at > now());
create policy "Members create own stories" on public.stories for insert to authenticated with check (auth.uid()=user_id);
create policy "Members delete own stories" on public.stories for delete to authenticated using (auth.uid()=user_id);
create policy "Only conversation participants read messages" on public.messages for select to authenticated using (auth.uid()=sender_id or auth.uid()=receiver_id);
create policy "Members send messages as themselves" on public.messages for insert to authenticated with check (auth.uid()=sender_id);
create policy "Receivers mark messages read" on public.messages for update to authenticated using (auth.uid()=receiver_id) with check (auth.uid()=receiver_id);

-- Storage bucket for post images. Create bucket as public for public post image URLs.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('post-media','post-media',true,10485760,array['image/jpeg','image/png','image/webp','image/gif'])
on conflict(id) do nothing;
create policy "Signed-in members upload to their own folder" on storage.objects for insert to authenticated
with check (bucket_id='post-media' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "Post media is publicly readable" on storage.objects for select
using(bucket_id='post-media');
create policy "Members delete their own media" on storage.objects for delete to authenticated
using(bucket_id='post-media' and (storage.foldername(name))[1]=auth.uid()::text);

-- Enable realtime updates for the feed and messages.
do $$ begin
  alter publication supabase_realtime add table public.posts;
exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null; when undefined_object then null; end $$;
