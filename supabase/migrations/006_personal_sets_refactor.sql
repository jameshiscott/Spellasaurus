-- ============================================================
-- Spellasaurus — Personal Sets Refactor
-- Migration: 006_personal_sets_refactor.sql
--
-- Personal lists now belong to the parent (via created_by) and
-- are assigned to children via a join table.  Previously they
-- were tied 1:1 to a single child via spelling_sets.child_id.
-- ============================================================

-- 1. Drop the old constraint (if it exists)
ALTER TABLE public.spelling_sets
  DROP CONSTRAINT IF EXISTS spelling_sets_class_or_child;

-- 2. New join table: many-to-many between personal sets and children
CREATE TABLE IF NOT EXISTS public.child_personal_sets (
  set_id      uuid NOT NULL REFERENCES public.spelling_sets(id) ON DELETE CASCADE,
  child_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  assigned_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (set_id, child_id)
);

-- 3. Migrate existing personal sets (child_id IS NOT NULL on spelling_sets)
--    → insert rows into the join table, then clear child_id
--    This MUST happen before adding the new constraint.
INSERT INTO public.child_personal_sets (set_id, child_id)
SELECT id, child_id
FROM public.spelling_sets
WHERE child_id IS NOT NULL
ON CONFLICT DO NOTHING;

UPDATE public.spelling_sets
SET child_id = NULL
WHERE child_id IS NOT NULL;

-- 4. Now that all rows are clean, add the new type-check constraint
ALTER TABLE public.spelling_sets
  DROP CONSTRAINT IF EXISTS spelling_sets_type_check;
ALTER TABLE public.spelling_sets
  ADD CONSTRAINT spelling_sets_type_check CHECK (
    -- class set: class_id set, child_id NULL
    (class_id IS NOT NULL AND child_id IS NULL) OR
    -- parent personal list: both NULL, owned via created_by
    (class_id IS NULL AND child_id IS NULL)
  );

-- 4. Enable RLS on the new join table
ALTER TABLE public.child_personal_sets ENABLE ROW LEVEL SECURITY;

-- Parents can manage assignments for their children and their own lists
DROP POLICY IF EXISTS "Parents can manage personal set assignments"
  ON public.child_personal_sets;
CREATE POLICY "Parents can manage personal set assignments"
  ON public.child_personal_sets FOR ALL
  USING (
    public.is_parent_of(child_id) AND
    EXISTS (
      SELECT 1 FROM public.spelling_sets
      WHERE id = set_id AND created_by = auth.uid()
    )
  )
  WITH CHECK (
    public.is_parent_of(child_id) AND
    EXISTS (
      SELECT 1 FROM public.spelling_sets
      WHERE id = set_id AND created_by = auth.uid()
    )
  );

-- Children can read their own assignments
DROP POLICY IF EXISTS "Children can read their own personal set assignments"
  ON public.child_personal_sets;
CREATE POLICY "Children can read their own personal set assignments"
  ON public.child_personal_sets FOR SELECT
  USING (child_id = auth.uid());

-- 5. SECURITY DEFINER helpers to break RLS recursion between
--    spelling_sets ↔ child_personal_sets.
CREATE OR REPLACE FUNCTION public.child_has_personal_set(set_uuid uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.child_personal_sets
    WHERE set_id = set_uuid AND child_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.parent_child_has_personal_set(set_uuid uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.child_personal_sets cps
    WHERE cps.set_id = set_uuid AND public.is_parent_of(cps.child_id)
  );
$$;

-- 6. Update spelling_sets RLS for the new personal-set ownership model
--    Old policy required child_id IS NOT NULL; now personal sets have child_id NULL.
DROP POLICY IF EXISTS "Parents can manage personal sets for their children"
  ON public.spelling_sets;

DROP POLICY IF EXISTS "Parents can manage their personal sets"
  ON public.spelling_sets;
CREATE POLICY "Parents can manage their personal sets"
  ON public.spelling_sets FOR ALL
  USING (
    class_id IS NULL AND created_by = auth.uid()
  )
  WITH CHECK (
    class_id IS NULL AND created_by = auth.uid()
  );

-- 7. Let children read personal sets assigned to them via the join table
DROP POLICY IF EXISTS "Children can read their class sets"
  ON public.spelling_sets;

DROP POLICY IF EXISTS "Children can read their class and personal sets"
  ON public.spelling_sets;
CREATE POLICY "Children can read their class and personal sets"
  ON public.spelling_sets FOR SELECT
  USING (
    (class_id IS NOT NULL AND public.child_is_in_class(class_id))
    OR public.child_has_personal_set(id)
  );

-- 8. Let parents read personal sets assigned to their children (not just their own)
DROP POLICY IF EXISTS "Parents can read personal sets assigned to their children"
  ON public.spelling_sets;
CREATE POLICY "Parents can read personal sets assigned to their children"
  ON public.spelling_sets FOR SELECT
  USING (public.parent_child_has_personal_set(id));

-- 9. Update spelling_words policies that referenced child_id on spelling_sets
DROP POLICY IF EXISTS "Children can read words in their sets"
  ON public.spelling_words;

CREATE POLICY "Children can read words in their sets"
  ON public.spelling_words FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.spelling_sets ss
      WHERE ss.id = set_id AND (
        (ss.class_id IS NOT NULL AND public.child_is_in_class(ss.class_id))
        OR public.child_has_personal_set(ss.id)
      )
    )
  );

DROP POLICY IF EXISTS "Parents can read words in their children's sets"
  ON public.spelling_words;

CREATE POLICY "Parents can read words in their children's sets"
  ON public.spelling_words FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.spelling_sets ss
      WHERE ss.id = set_id AND (
        ss.created_by = auth.uid()
        OR (ss.class_id IS NOT NULL AND EXISTS (
          SELECT 1 FROM public.class_students cs
          WHERE cs.class_id = ss.class_id AND public.is_parent_of(cs.child_id)
        ))
      )
    )
  );
