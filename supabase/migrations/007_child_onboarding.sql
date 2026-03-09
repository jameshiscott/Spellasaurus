-- ============================================================
-- Spellasaurus — Child Onboarding (Display Name + Dinosaur)
-- Migration: 007_child_onboarding.sql
-- ============================================================

-- Display name: publicly visible, unique, chosen during onboarding
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS display_name text;

-- Dinosaur avatar: type (e.g. 'trex', 'stego') + colour (e.g. 'green', 'purple')
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS dino_type text,
  ADD COLUMN IF NOT EXISTS dino_color text;

-- Whether the child has completed the onboarding flow
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS onboarding_complete boolean NOT NULL DEFAULT false;

-- Display names must be unique across all profiles
CREATE UNIQUE INDEX IF NOT EXISTS profiles_display_name_unique
  ON public.profiles (display_name)
  WHERE display_name IS NOT NULL;

-- RPC: check whether a display name is already taken
CREATE OR REPLACE FUNCTION public.is_display_name_available(p_name text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE display_name = p_name
  );
$$;

-- RPC: save child onboarding choices
CREATE OR REPLACE FUNCTION public.complete_child_onboarding(
  p_child_id    uuid,
  p_display_name text,
  p_dino_type   text,
  p_dino_color  text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET display_name        = p_display_name,
      dino_type           = p_dino_type,
      dino_color          = p_dino_color,
      onboarding_complete = true
  WHERE id   = p_child_id
    AND role = 'child';
END;
$$;
