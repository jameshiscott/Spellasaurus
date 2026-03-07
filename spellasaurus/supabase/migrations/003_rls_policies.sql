-- ============================================================
-- Spellasaurus — Row Level Security Policies
-- Migration: 003_rls_policies.sql
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- SECURITY DEFINER helpers — these run as the DB owner and
-- bypass RLS, breaking the cross-table recursion chains.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_school_admin_of(school_uuid uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.schools WHERE id = school_uuid AND admin_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_teacher_of_class(class_uuid uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.classes WHERE id = class_uuid AND teacher_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.child_is_in_class(class_uuid uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.class_students WHERE class_id = class_uuid AND child_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_parent_of(child_uuid uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.parent_children WHERE child_id = child_uuid AND parent_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.school_id_for_class(class_uuid uuid)
RETURNS uuid LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $$
  SELECT school_id FROM public.classes WHERE id = class_uuid LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.teacher_id_for_class(class_uuid uuid)
RETURNS uuid LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $$
  SELECT teacher_id FROM public.classes WHERE id = class_uuid LIMIT 1;
$$;

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

-- Parents can read their children's profiles (no cross-table recursion — parent_children has simple policy)
CREATE POLICY "Parents can read child profiles"
  ON public.profiles FOR SELECT
  USING (public.is_parent_of(id));

-- Teachers can read profiles of students in their classes
CREATE POLICY "Teachers can read student profiles in their class"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.class_students cs
      WHERE cs.child_id = id AND public.is_teacher_of_class(cs.class_id)
    )
  );

-- ────────────────────────────────────────────────
-- schools
-- ────────────────────────────────────────────────
CREATE POLICY "School admins can manage their school"
  ON public.schools FOR ALL
  USING (admin_id = auth.uid())
  WITH CHECK (admin_id = auth.uid());

-- Teachers can read the school their class belongs to (use helper, no recursion)
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

-- Admin check uses helper to avoid schools ↔ classes recursion
CREATE POLICY "School admins can manage classes in their schools"
  ON public.classes FOR ALL
  USING (public.is_school_admin_of(school_id))
  WITH CHECK (public.is_school_admin_of(school_id));

CREATE POLICY "Teachers can read their classes"
  ON public.classes FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "Teachers can update their classes"
  ON public.classes FOR UPDATE
  USING (teacher_id = auth.uid());

-- Children use helper to avoid class_students ↔ classes recursion
CREATE POLICY "Children can read their class"
  ON public.classes FOR SELECT
  USING (public.child_is_in_class(id));

-- Parents use helper
CREATE POLICY "Parents can read their children's class"
  ON public.classes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.class_students cs
      WHERE cs.class_id = id AND public.is_parent_of(cs.child_id)
    )
  );

-- ────────────────────────────────────────────────
-- spelling_sets
-- ────────────────────────────────────────────────
CREATE POLICY "Teachers can manage class spelling sets"
  ON public.spelling_sets FOR ALL
  USING (
    class_id IS NOT NULL AND public.is_teacher_of_class(class_id)
  )
  WITH CHECK (
    class_id IS NOT NULL AND public.is_teacher_of_class(class_id)
  );

CREATE POLICY "School admins can manage class sets"
  ON public.spelling_sets FOR ALL
  USING (
    class_id IS NOT NULL AND
    public.is_school_admin_of(public.school_id_for_class(class_id))
  )
  WITH CHECK (
    class_id IS NOT NULL AND
    public.is_school_admin_of(public.school_id_for_class(class_id))
  );

CREATE POLICY "Parents can manage personal sets for their children"
  ON public.spelling_sets FOR ALL
  USING (
    child_id IS NOT NULL AND public.is_parent_of(child_id)
  )
  WITH CHECK (
    child_id IS NOT NULL AND public.is_parent_of(child_id)
  );

CREATE POLICY "Children can read their class sets"
  ON public.spelling_sets FOR SELECT
  USING (
    (class_id IS NOT NULL AND public.child_is_in_class(class_id))
    OR (child_id = auth.uid())
  );

-- ────────────────────────────────────────────────
-- spelling_words
-- ────────────────────────────────────────────────
CREATE POLICY "Set owners and teachers can manage words"
  ON public.spelling_words FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.spelling_sets ss
      WHERE ss.id = set_id AND (
        ss.created_by = auth.uid()
        OR (ss.class_id IS NOT NULL AND public.is_teacher_of_class(ss.class_id))
        OR (ss.class_id IS NOT NULL AND
            public.is_school_admin_of(public.school_id_for_class(ss.class_id)))
      )
    )
  );

CREATE POLICY "Children can read words in their sets"
  ON public.spelling_words FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.spelling_sets ss
      WHERE ss.id = set_id AND (
        (ss.class_id IS NOT NULL AND public.child_is_in_class(ss.class_id))
        OR ss.child_id = auth.uid()
      )
    )
  );

CREATE POLICY "Parents can read words in their children's sets"
  ON public.spelling_words FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.spelling_sets ss
      WHERE ss.id = set_id AND (
        (ss.child_id IS NOT NULL AND public.is_parent_of(ss.child_id))
        OR (ss.class_id IS NOT NULL AND EXISTS (
          SELECT 1 FROM public.class_students cs
          WHERE cs.class_id = ss.class_id AND public.is_parent_of(cs.child_id)
        ))
      )
    )
  );

-- ────────────────────────────────────────────────
-- child_practice_settings
-- ────────────────────────────────────────────────
CREATE POLICY "Parents can manage practice settings for their children"
  ON public.child_practice_settings FOR ALL
  USING (public.is_parent_of(child_id))
  WITH CHECK (public.is_parent_of(child_id));

CREATE POLICY "Children can read their own practice settings"
  ON public.child_practice_settings FOR SELECT
  USING (child_id = auth.uid());

-- ────────────────────────────────────────────────
-- class_students
-- ────────────────────────────────────────────────
CREATE POLICY "Teachers and admins can manage class students"
  ON public.class_students FOR ALL
  USING (
    public.is_teacher_of_class(class_id)
    OR public.is_school_admin_of(public.school_id_for_class(class_id))
  )
  WITH CHECK (
    public.is_teacher_of_class(class_id)
    OR public.is_school_admin_of(public.school_id_for_class(class_id))
  );

CREATE POLICY "Children can read their own enrollment"
  ON public.class_students FOR SELECT
  USING (child_id = auth.uid());

CREATE POLICY "Parents can read their children's enrollment"
  ON public.class_students FOR SELECT
  USING (public.is_parent_of(child_id));

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
  USING (public.is_parent_of(child_id));

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
      WHERE ps.id = session_id AND public.is_parent_of(ps.child_id)
    )
  );

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
