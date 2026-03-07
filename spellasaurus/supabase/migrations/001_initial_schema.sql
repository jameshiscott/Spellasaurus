-- ============================================================
-- Spellasaurus — Initial Schema
-- Migration: 001_initial_schema.sql
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ────────────────────────────────────────────────
-- profiles
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id              uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role            text NOT NULL CHECK (role IN ('school_admin','teacher','parent','child')),
  full_name       text NOT NULL,
  avatar_url      text,
  date_of_birth   date,         -- child profiles only
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────
-- schools
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.schools (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  address     text,
  admin_id    uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────
-- classes
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.classes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   uuid NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  teacher_id  uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  name        text NOT NULL,
  school_year int  NOT NULL DEFAULT EXTRACT(YEAR FROM now()),
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────
-- spelling_sets
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.spelling_sets (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id      uuid REFERENCES public.classes(id) ON DELETE CASCADE,    -- null for personal sets
  child_id      uuid REFERENCES public.profiles(id) ON DELETE CASCADE,   -- null for class sets
  created_by    uuid NOT NULL REFERENCES public.profiles(id),
  name          text NOT NULL,
  week_number   int,
  week_start    date,
  created_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT spelling_sets_class_or_child CHECK (
    (class_id IS NOT NULL AND child_id IS NULL) OR
    (class_id IS NULL AND child_id IS NOT NULL)
  )
);

-- ────────────────────────────────────────────────
-- spelling_words
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.spelling_words (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  set_id                uuid NOT NULL REFERENCES public.spelling_sets(id) ON DELETE CASCADE,
  word                  text NOT NULL,
  hint                  text,                    -- manual clue from teacher/parent
  ai_description        text,                    -- AI-generated definition
  ai_example_sentence   text,                    -- AI-generated example sentence
  audio_url             text,                    -- URL to .mp3 in Supabase Storage
  ai_generated_at       timestamptz,             -- timestamp of last AI generation
  sort_order            int NOT NULL DEFAULT 0,
  created_at            timestamptz NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────
-- child_practice_settings
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.child_practice_settings (
  child_id              uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  show_description      boolean NOT NULL DEFAULT true,
  show_example_sentence boolean NOT NULL DEFAULT true,
  play_tts_audio        boolean NOT NULL DEFAULT true,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────
-- class_students
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.class_students (
  class_id    uuid NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
  child_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  enrolled_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (class_id, child_id)
);

-- ────────────────────────────────────────────────
-- parent_children
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.parent_children (
  parent_id  uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  child_id   uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  PRIMARY KEY (parent_id, child_id)
);

-- ────────────────────────────────────────────────
-- practice_sessions
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.practice_sessions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id      uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  set_id        uuid NOT NULL REFERENCES public.spelling_sets(id) ON DELETE CASCADE,
  score         int NOT NULL DEFAULT 0,
  total_words   int NOT NULL DEFAULT 0,
  completed_at  timestamptz NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────
-- practice_answers
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.practice_answers (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id    uuid NOT NULL REFERENCES public.practice_sessions(id) ON DELETE CASCADE,
  word_id       uuid NOT NULL REFERENCES public.spelling_words(id) ON DELETE CASCADE,
  typed_answer  text NOT NULL,
  is_correct    boolean NOT NULL DEFAULT false
);

-- ────────────────────────────────────────────────
-- Indexes
-- ────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_classes_school_id     ON public.classes(school_id);
CREATE INDEX IF NOT EXISTS idx_classes_teacher_id    ON public.classes(teacher_id);
CREATE INDEX IF NOT EXISTS idx_spelling_sets_class   ON public.spelling_sets(class_id);
CREATE INDEX IF NOT EXISTS idx_spelling_sets_child   ON public.spelling_sets(child_id);
CREATE INDEX IF NOT EXISTS idx_spelling_sets_week    ON public.spelling_sets(week_start);
CREATE INDEX IF NOT EXISTS idx_spelling_words_set    ON public.spelling_words(set_id);
CREATE INDEX IF NOT EXISTS idx_class_students_class  ON public.class_students(class_id);
CREATE INDEX IF NOT EXISTS idx_class_students_child  ON public.class_students(child_id);
CREATE INDEX IF NOT EXISTS idx_parent_children_par   ON public.parent_children(parent_id);
CREATE INDEX IF NOT EXISTS idx_sessions_child        ON public.practice_sessions(child_id);
CREATE INDEX IF NOT EXISTS idx_sessions_set          ON public.practice_sessions(set_id);
CREATE INDEX IF NOT EXISTS idx_answers_session       ON public.practice_answers(session_id);
