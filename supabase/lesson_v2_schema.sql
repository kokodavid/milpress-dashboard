-- Lesson v2 schema (Supabase)
create extension if not exists "pgcrypto";

do $$ begin
  create type lesson_type_enum as enum ('letter', 'word', 'sentence');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type lesson_step_type_enum as enum (
    'introduction',
    'demonstration',
    'practice',
    'assessment',
    'blending',
    'sound_discrimination',
    'sound_item_matching',
    'guided_reading',
    'practice_game',
    'sound_presence_check',
    'missing_letters',
    'matching_words',
    'word_reading',
    'sentence_reading',
    'mini_story_card'
  );
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

-- ── Step type registry ────────────────────────────────────────────────────────
-- Migrate lesson_steps.step_type from enum to text so custom types can be used.
-- Run once against the live database:
--
--   alter table lesson_steps
--     alter column step_type type text using step_type::text;
--
-- (Existing rows are preserved; the enum labels are stored as plain text.)

create table if not exists lesson_step_types (
  id           uuid        primary key default gen_random_uuid(),
  key          text        unique not null,
  display_name text        not null,
  description  text        not null default '',
  category     text        not null default 'Foundation',
  icon_name    text        not null default 'extension',
  preview_url  text,
  is_system    boolean     not null default false,
  -- JSONB array of field definitions for the visual form builder.
  -- Each element: { name, label, field_type, is_required, hint? }
  -- field_type is one of: 'text', 'image_url', 'audio_url'
  field_schema jsonb       not null default '[]'::jsonb,
  created_at   timestamptz default now()
);

-- Add field_schema to an existing database (run once):
--
--   alter table lesson_step_types
--     add column if not exists field_schema jsonb not null default '[]'::jsonb;

-- Seed the 15 built-in step types (idempotent).
insert into lesson_step_types (key, display_name, description, category, icon_name, is_system) values
  ('introduction',       'Introduction',        'Introduces the lesson with display text and audio',                  'Foundation',    'info_outline',                true),
  ('demonstration',      'Demonstration',       'Shows visual demonstrations with images and feedback',               'Foundation',    'play_circle_outline',         true),
  ('practice',           'Practice',            'Practice exercises with labeled image and sound pairs',              'Foundation',    'edit_outlined',               true),
  ('assessment',         'Assessment',          'Multiple-choice quiz with correct/incorrect options',                'Assessment',    'quiz_outlined',               true),
  ('practice_game',      'Practice Game',       'Timed game for students to identify correct options',                'Assessment',    'videogame_asset_outlined',    true),
  ('blending',           'Blending',            'Students tap and blend phonemes into words',                         'Sound & Phonics','merge_type',                 true),
  ('sound_discrimination','Sound Discrimination','Students identify if a target sound appears in a word',             'Sound & Phonics','hearing',                    true),
  ('sound_item_matching','Sound Item Matching', 'Students match sounds to the correct items',                         'Sound & Phonics','compare_arrows',             true),
  ('sound_presence_check','Sound Presence Check','Yes/no questions about whether a sound appears in a word',         'Sound & Phonics','record_voice_over_outlined', true),
  ('guided_reading',     'Guided Reading',      'Word-by-word guided reading with phoneme breakdown',                 'Reading',       'menu_book_outlined',          true),
  ('word_reading',       'Word Reading',        'Students read individual words aloud',                               'Reading',       'text_fields',                 true),
  ('sentence_reading',   'Sentence Reading',    'Students read full sentences token by token',                        'Reading',       'subject',                     true),
  ('missing_letters',    'Missing Letters',     'Fill-in-the-blank letter exercises',                                 'Reading',       'spellcheck',                  true),
  ('matching_words',     'Matching Words',      'Match words to images, sounds, or other words',                      'Reading',       'swap_horiz',                  true),
  ('mini_story_card',    'Mini Story Card',     'Short story cards with audio and optional call-to-action',           'Story',         'auto_stories_outlined',       true)
on conflict (key) do nothing;
