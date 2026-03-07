// Spellasaurus — Edge Function: create-child-account
// Called by a parent to create a child auth user + profile + parent_children link.
// Uses service role so it can create users server-side.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
    const { full_name, email, password, date_of_birth, parent_id } =
      await req.json();

    if (!full_name || !email || !password || !date_of_birth || !parent_id) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400 }
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // ── 1. Create the auth user ────────────────────────────────────────────
    const { data: authData, error: authError } =
      await supabase.auth.admin.createUser({
        email,
        password,
        email_confirm: true, // auto-confirm; child doesn't need email verification
        user_metadata: {
          full_name,
          role: "child",
          date_of_birth,
        },
      });

    if (authError || !authData.user) {
      return new Response(
        JSON.stringify({ error: authError?.message ?? "Failed to create user" }),
        { status: 400 }
      );
    }

    const childId = authData.user.id;

    // ── 2. Link parent → child ─────────────────────────────────────────────
    const { error: linkError } = await supabase
      .from("parent_children")
      .insert({ parent_id, child_id: childId });

    if (linkError) {
      console.error("Failed to link parent/child:", linkError);
      // Don't fail the whole request — profile was created
    }

    // ── 3. Create default practice settings ───────────────────────────────
    await supabase.from("child_practice_settings").insert({
      child_id: childId,
    });

    return new Response(
      JSON.stringify({ success: true, child_id: childId }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("create-child-account error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
    });
  }
});
