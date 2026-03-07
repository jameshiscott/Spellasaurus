-- ============================================================
-- Spellasaurus — Row Level Security Policies
-- Migration: 003_rls_policies.sql
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schools                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.spelling_sets          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.spelling_words         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.child_practice_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_students         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_children        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.practice_sessions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.practice_answers       ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────
-- profiles
-- ────────────────────────────────────────────────
CREATE POLICY "Users can read their own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Parents can read their children's profiles
CREATE POLICY "Parents can read child profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.parent_children pc
      WHERE pc.parent_id = auth.uid() AND pc.child_id = id
    )
  );

-- Teachers/admins can read profiles in their school
CREATE POLICY "Teachers can read student profiles in their class"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.class_students cs
      JOIN public.classes c ON c.id = cs.class_id
      WHERE cs.child_id = id AND c.teacher_id = auth.uid()
    )
  );

-- ────────────────────────────────────────────────
-- schools
-- ────────────────────────────────────────────────
CREATE POLICY "School admins can manage their school"
  ON public.schools FOR ALL
  USING (admin_id = auth.uid())
  WITH CHECK (admin_id = auth.uid());

CREATE POLICY "Teachers can read schools they work for"
  ON public.schools FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.classes c
      WHERE c.school_id = id AND c.teacher_id = auth.uid()
    )
  );

-- ────────────────────────────────────────────────
-- classes
-- ────────────────────────────────────────────────
CREATE POLICY "School admins can manage classes in their schools"
  ON public.classes FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.schools s
      WHERE s.id = school_id AND s.admin_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can read and update their classes"
  ON public.classes FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "Teachers can update their classes"
  ON public.classes FOR UPDATE
  USING (teacher_id = auth.uid());

CREATE POLICY "Children can read their class"
  ON public.classes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.class_students cs
      WHERE cs.class_id = id AND cs.child_id = auth.uid()
    )
  );

CREATE POLICY "Parents can read their children's class"
  ON public.classes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.class_students cs
      JOIN public.parent_children pc ON pc.child_id = cs.child_id
      WHERE cs.class_id = id AND pc.parent_id = auth.uid()
    )
  );

-- ────────────────────────────────────────────────
-- spelling_sets
-- ────────────────────────────────────────────────
CREATE POLICY "Teachers can manage class spelling sets"
  ON public.spelling_sets FOR ALL
  USING (
    class_id IS NOT NULL AND
    EXISTS (
      SELECT 1 FROM public.classes c
      WHERE c.id = class_id AND c.teacher_id = auth.uid()
    )
  );

CREATE POLICY "School admins can manage class sets"
  ON public.spelling_sets FOR ALL
  USING (
    class_id IS NOT NULL AND
    EXISTS (
      SELECT 1 FROM public.classes c
      JOIN public.schools s ON s.id = c.school_id
      WHERE c.id = class_id AND s.admin_id = auth.uid()
    )
  );

CREATE POLICY "Parents can manage personal sets for their children"
  ON public.spelling_sets FOR ALL
  USING (
    child_id IS NOT NULL AND
    EXISTS (
      SELECT 1 FROM public.parent_children pc
      WHERE pc.child_id = spelling_sets.child_id AND pc.parent_id = auth.uid()
    )
  );

CREATE POLICY "Children can read their class sets"
  ON public.spelling_sets FOR SELECT
  USING (
    (class_id IS NOT NULL AND
     EXISTS (
       SELECT 1 FROM public.class_students cs
       WHERE cs.class_id = spelling_sets.class_id AND cs.child_id = auth.uid()
     )
    )
    OR
    (child_id = auth.uid())
  );

-- ────────────────────────────────────────────────
-- spelling_words
-- ────────────────────────────────────────────────
CREATE POLICY "Users who can manage the set can manage words"
  ON public.spelling_words FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.spelling_sets ss
      WHERE ss.id = set_id AND ss.created_by = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM public.spelling_sets ss
      JOIN public.classes c ON c.id = ss.class_id
      WHERE ss.id = set_id AND c.teacher_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM public.spelling_sets ss
      JOIN public.classes c ON c.id = ss.class_id
      JOIN public.schools s ON s.id = c.school_id
      WHERE ss.id = set_id AND s.admin_id = auth.uid()
    )
  );

CREATE POLICY "Children can read words in their sets"
  ON public.spelling_words FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.spelling_sets ss
      LEFT JOIN public.class_students cs ON cs.class_id = ss.class_id
      WHERE ss.id = set_id AND (cs.child_id = auth.uid() OR ss.child_id = auth.uid())
    )
  );

CREATE POLICY "Parents can read words in their children's sets"
  ON public.spelling_words FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.spelling_sets ss
      JOIN public.parent_children pc ON pc.child_id = ss.child_id
      WHERE ss.id = set_id AND pc.parent_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM public.spelling_sets ss
      JOIN public.classes c ON c.id = ss.class_id
      JOIN public.class_students cs ON cs.class_id = c.id
      JOIN public.parent_children pc ON pc.child_id = cs.child_id
      WHERE ss.id = set_id AND pc.parent_id = auth.uid()
    )
  );

-- ────────────────────────────────────────────────
-- child_practice_settings
-- ────────────────────────────────────────────────
CREATE POLICY "Parents can manage practice settings for their children"
  ON public.child_practice_settings FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.parent_children pc
      WHERE pc.child_id = child_id AND pc.parent_id = auth.uid()
    )
  );

CREATE POLICY "Children can read their own practice settings"
  ON public.child_practice_settings FOR SELECT
  USING (child_id = auth.uid());

-- ────────────────────────────────────────────────
-- class_students
-- ────────────────────────────────────────────────
CREATE POLICY "Teachers and admins can manage class students"
  ON public.class_students FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.classes c
      WHERE c.id = class_id AND c.teacher_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM public.classes c
      JOIN public.schools s ON s.id = c.school_id
      WHERE c.id = class_id AND s.admin_id = auth.uid()
    )
  );

CREATE POLICY "Children can read their own enrollment"
  ON public.class_students FOR SELECT
  USING (child_id = auth.uid());

CREATE POLICY "Parents can read their children's enrollment"
  ON public.class_students FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.parent_children pc
      WHERE pc.child_id = class_students.child_id AND pc.parent_id = auth.uid()
    )
  );

-- ────────────────────────────────────────────────
-- parent_children
-- ────────────────────────────────────────────────
CREATE POLICY "Parents can read their own parent_children rows"
  ON public.parent_children FOR SELECT
  USING (parent_id = auth.uid());

CREATE POLICY "Parents can insert their own parent_children rows"
  ON public.parent_children FOR INSERT
  WITH CHECK (parent_id = auth.uid());

-- ────────────────────────────────────────────────
-- practice_sessions
-- ────────────────────────────────────────────────
CREATE POLICY "Children can insert and read their own sessions"
  ON public.practice_sessions FOR ALL
  USING (child_id = auth.uid())
  WITH CHECK (child_id = auth.uid());

CREATE POLICY "Parents can read their children's sessions"
  ON public.practice_sessions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.parent_children pc
      WHERE pc.child_id = practice_sessions.child_id AND pc.parent_id = auth.uid()
    )
  );

-- ────────────────────────────────────────────────
-- practice_answers
-- ────────────────────────────────────────────────
CREATE POLICY "Children can insert and read their own answers"
  ON public.practice_answers FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.practice_sessions ps
      WHERE ps.id = session_id AND ps.child_id = auth.uid()
    )
  );

CREATE POLICY "Parents can read their children's answers"
  ON public.practice_answers FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.practice_sessions ps
      JOIN public.parent_children pc ON pc.child_id = ps.child_id
      WHERE ps.id = session_id AND pc.parent_id = auth.uid()
    )
  );
