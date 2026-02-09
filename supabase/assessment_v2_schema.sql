-- Assessment V2 schema (Supabase)
-- Hierarchy: Course → Assessment → Levels → Sublevels → Questions (JSONB)
-- Progress tracked per user per sublevel in a dedicated table.

create extension if not exists "pgcrypto";

-- ============================================================
-- Table 1: course_assessments (one assessment per course)
-- ============================================================
create table if not exists course_assessments (
  id          uuid primary key default gen_random_uuid(),
  course_id   uuid not null unique references courses(id) on delete cascade,
  title       text not null,
  description text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create unique index if not exists course_assessments_course_id_idx
  on course_assessments (course_id);

-- ============================================================
-- Table 2: assessment_levels (ordered levels within an assessment)
-- ============================================================
create table if not exists assessment_levels (
  id              uuid primary key default gen_random_uuid(),
  assessment_id   uuid not null references course_assessments(id) on delete cascade,
  title           text not null,
  description     text,
  display_order   int not null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create unique index if not exists assessment_levels_order_idx
  on assessment_levels (assessment_id, display_order);

-- ============================================================
-- Table 3: assessment_sublevels (ordered sublevels within a level)
--   questions column is JSONB for fully dynamic question formats.
--   Example questions structure:
--   [
--     {
--       "type": "multiple_choice",
--       "prompt": "What is the capital of Kenya?",
--       "options": ["Nairobi", "Mombasa", "Kisumu", "Nakuru"],
--       "correct_answer": "Nairobi",
--       "points": 10
--     },
--     {
--       "type": "fill_in_blank",
--       "prompt": "The sun rises in the ___",
--       "correct_answer": "east",
--       "points": 5
--     },
--     {
--       "type": "true_false",
--       "prompt": "Water boils at 100°C",
--       "correct_answer": true,
--       "points": 5
--     }
--   ]
-- ============================================================
create table if not exists assessment_sublevels (
  id              uuid primary key default gen_random_uuid(),
  level_id        uuid not null references assessment_levels(id) on delete cascade,
  title           text not null,
  description     text,
  display_order   int not null,
  questions       jsonb not null default '[]'::jsonb,
  passing_score   int not null default 70,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create unique index if not exists assessment_sublevels_order_idx
  on assessment_sublevels (level_id, display_order);

create index if not exists assessment_sublevels_level_id_idx
  on assessment_sublevels (level_id);

-- ============================================================
-- Table 4: assessment_v2_progress (per-user, per-sublevel tracking)
--   Written by the mobile app during assessment attempts.
--   Dashboard reads this data and can reset progress.
-- ============================================================
create table if not exists assessment_v2_progress (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null,
  sublevel_id     uuid not null references assessment_sublevels(id) on delete cascade,
  assessment_id   uuid not null references course_assessments(id) on delete cascade,
  score           int,
  max_score       int,
  is_passed       boolean not null default false,
  attempts        int not null default 0,
  answers         jsonb,
  started_at      timestamptz,
  completed_at    timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create unique index if not exists assessment_v2_progress_user_sublevel_idx
  on assessment_v2_progress (user_id, sublevel_id);

create index if not exists assessment_v2_progress_assessment_idx
  on assessment_v2_progress (assessment_id);

create index if not exists assessment_v2_progress_user_idx
  on assessment_v2_progress (user_id);
