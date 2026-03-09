-- ============================================================
-- Spellasaurus — Coins / Gamification
-- Migration: 005_coins.sql
-- ============================================================

-- Add coin balance to every profile (children accumulate coins)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS coin_balance int NOT NULL DEFAULT 0;

-- RPC used by the app to safely increment a child's coin balance
-- SECURITY DEFINER so it runs as the DB owner and bypasses RLS
CREATE OR REPLACE FUNCTION public.add_coins(p_child_id uuid, p_amount int)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE public.profiles
  SET coin_balance = coin_balance + p_amount
  WHERE id = p_child_id
    AND role = 'child'
    AND p_amount > 0;
$$;
