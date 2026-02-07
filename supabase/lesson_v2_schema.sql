-- Lesson v2 schema (Supabase)
create extension if not exists "pgcrypto";

do $$ begin
  create type lesson_type_enum as enum ('letter', 'word', 'sentence');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type lesson_step_type_enum as enum ('introduction', 'demonstration', 'practice', 'assessment');
exception
  when duplicate_object then null;
end $$;

create table if not exists new_lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null,
  title text not null,
  lesson_type lesson_type_enum not null,
  display_order int not null
);

create table if not exists lesson_steps (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references new_lessons(id) on delete cascade,
  step_key text not null,
  step_type lesson_step_type_enum not null,
  position int not null,
  required boolean not null,
  config jsonb
);

create unique index if not exists new_lessons_module_order_idx
  on new_lessons (module_id, display_order);

create unique index if not exists lesson_steps_lesson_position_idx
  on lesson_steps (lesson_id, position);

create index if not exists lesson_steps_step_type_idx
  on lesson_steps (step_type);
