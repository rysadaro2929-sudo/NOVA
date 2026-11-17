-- NOVA Social initial schema. Run in Supabase SQL Editor after reviewing.
create extension if not exists pgcrypto;
create table if not exists public.profiles (id uuid primary key references auth.users(id) on delete cascade, username text unique, display_name text, avatar_url text, bio text, created_at timestamptz not null default now());
create table if not exists public.posts (id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade, content text, media_url text, media_type text check (media_type in ('image','video') or media_type is null), visibility text not null default 'public' check (visibility in ('public','followers','private')), created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.post_likes (post_id uuid not null references public.posts(id) on delete cascade, user_id uuid not null references auth.users(id) on delete cascade, created_at timestamptz not null default now(), primary key(post_id,user_id));
create table if not exists public.comments (id uuid primary key default gen_random_uuid(), post_id uuid not null references public.posts(id) on delete cascade, user_id uuid not null references auth.users(id) on delete cascade, body text not null check (char_length(body) between 1 and 5000), created_at timestamptz not null default now());
create table if not exists public.follows (follower_id uuid not null references auth.users(id) on delete cascade, following_id uuid not null references auth.users(id) on delete cascade, created_at timestamptz not null default now(), primary key(follower_id,following_id), check(follower_id <> following_id));
create table if not exists public.conversations (id uuid primary key default gen_random_uuid(), created_at timestamptz not null default now());
create table if not exists public.conversation_members (conversation_id uuid not null references public.conversations(id) on delete cascade, user_id uuid not null references auth.users(id) on delete cascade, joined_at timestamptz not null default now(), primary key(conversation_id,user_id));
create table if not exists public.messages (id uuid primary key default gen_random_uuid(), conversation_id uuid not null references public.conversations(id) on delete cascade, sender_id uuid not null references auth.users(id) on delete cascade, body text, media_url text, created_at timestamptz not null default now(), read_at timestamptz);
create index if not exists posts_created_at_idx on public.posts(created_at desc);
create index if not exists comments_post_created_idx on public.comments(post_id,created_at desc);
create index if not exists messages_conversation_created_idx on public.messages(conversation_id,created_at);
-- Enable RLS on every user-data table.
alter table public.profiles enable row level security; alter table public.posts enable row level security; alter table public.post_likes enable row level security; alter table public.comments enable row level security; alter table public.follows enable row level security; alter table public.conversation_members enable row level security; alter table public.conversations enable row level security; alter table public.messages enable row level security;
-- Profiles: public read; owners update their own profile.
create policy "Profiles are readable" on public.profiles for select using (true);
create policy "Users insert own profile" on public.profiles for insert with check (auth.uid()=id);
create policy "Users update own profile" on public.profiles for update using (auth.uid()=id) with check (auth.uid()=id);
-- Posts: public posts readable; owner controls own posts. Followers-only policy is intentionally deferred until follow relationship policy is finalized.
create policy "Public posts readable" on public.posts for select using (visibility='public' or auth.uid()=user_id);
create policy "Users create own posts" on public.posts for insert with check (auth.uid()=user_id);
create policy "Users update own posts" on public.posts for update using (auth.uid()=user_id) with check (auth.uid()=user_id);
create policy "Users delete own posts" on public.posts for delete using (auth.uid()=user_id);
create policy "Likes readable" on public.post_likes for select using (true);
create policy "Users like as themselves" on public.post_likes for insert with check (auth.uid()=user_id);
create policy "Users unlike themselves" on public.post_likes for delete using (auth.uid()=user_id);
create policy "Comments readable" on public.comments for select using (true);
create policy "Users comment as themselves" on public.comments for insert with check (auth.uid()=user_id);
create policy "Users delete own comments" on public.comments for delete using (auth.uid()=user_id);
create policy "Follows readable" on public.follows for select using (true);
create policy "Users follow as themselves" on public.follows for insert with check (auth.uid()=follower_id);
create policy "Users unfollow as themselves" on public.follows for delete using (auth.uid()=follower_id);
-- Messaging: SECURITY DEFINER helper avoids recursive RLS evaluation on conversation_members.
create or replace function public.is_conversation_member(target_conversation uuid, target_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.conversation_members m where m.conversation_id=target_conversation and m.user_id=target_user); $$;
revoke all on function public.is_conversation_member(uuid,uuid) from public;
grant execute on function public.is_conversation_member(uuid,uuid) to authenticated;
create policy "Authenticated users create conversations" on public.conversations for insert with check (auth.uid() is not null);
create policy "Members can see own conversations" on public.conversations for select using (public.is_conversation_member(id));
create policy "Members can see membership" on public.conversation_members for select using (user_id=auth.uid() or public.is_conversation_member(conversation_id));
create policy "Users add themselves to conversations" on public.conversation_members for insert with check (auth.uid()=user_id);

create policy "Members read messages" on public.messages for select using (exists(select 1 from public.conversation_members m where m.conversation_id=messages.conversation_id and m.user_id=auth.uid()));
create policy "Members send messages" on public.messages for insert with check (auth.uid()=sender_id and exists(select 1 from public.conversation_members m where m.conversation_id=messages.conversation_id and m.user_id=auth.uid()));
