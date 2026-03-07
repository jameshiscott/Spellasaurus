// Spellasaurus — Edge Function: create-child-account
// Called by a parent to create a child auth user + profile + parent_children link.
// Uses service role so it can create users server-side.
// Child accounts use username@spellasaurus.com — no real email needed.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const EMAIL_DOMAIN = "@spellasaurus.com";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { full_name, username, password, date_of_birth, parent_id } =
      await req.json();

    if (!full_name || !username || !password || !date_of_birth || !parent_id) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Normalise username: lowercase, strip spaces
    const cleanUsername = username.trim().toLowerCase().replace(/\s+/g, "");
    if (!/^[a-z0-9._-]+$/.test(cleanUsername)) {
      return new Response(
        JSON.stringify({ error: "Username can only contain letters, numbers, dots, hyphens and underscores" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const email = `${cleanUsername}${EMAIL_DOMAIN}`;

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // ── 1. Check username is unique ───────────────────────────────────────
    const { data: existing } = await supabase.auth.admin.listUsers();
    const taken = existing?.users?.some((u) => u.email === email);
    if (taken) {
      return new Response(
        JSON.stringify({ error: "That username is already taken. Please choose another." }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── 2. Create the auth user ────────────────────────────────────────────
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
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const childId = authData.user.id;

    // ── 3. Link parent → child ─────────────────────────────────────────────
    const { error: linkError } = await supabase
      .from("parent_children")
      .insert({ parent_id, child_id: childId });

    if (linkError) {
      console.error("Failed to link parent/child:", linkError);
    }

    // ── 4. Create default practice settings ───────────────────────────────
    await supabase.from("child_practice_settings").insert({
      child_id: childId,
    });

    return new Response(
      JSON.stringify({ success: true, child_id: childId, email }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("create-child-account error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

serve(async (req) => {
  try {
    const { full_name, username, password, date_of_birth, parent_id } =
      await req.json();

    if (!full_name || !username || !password || !date_of_birth || !parent_id) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400 }
      );
    }

    // Normalise username: lowercase, strip spaces
    const cleanUsername = username.trim().toLowerCase().replace(/\s+/g, "");
    if (!/^[a-z0-9._-]+$/.test(cleanUsername)) {
      return new Response(
        JSON.stringify({ error: "Username can only contain letters, numbers, dots, hyphens and underscores" }),
        { status: 400 }
      );
    }

    const email = `${cleanUsername}${EMAIL_DOMAIN}`;

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // ── 1. Check username is unique ───────────────────────────────────────
    const { data: existing } = await supabase.auth.admin.listUsers();
    const taken = existing?.users?.some((u) => u.email === email);
    if (taken) {
      return new Response(
        JSON.stringify({ error: "That username is already taken. Please choose another." }),
        { status: 409 }
      );
    }

    // ── 2. Create the auth user ────────────────────────────────────────────
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

    // ── 3. Link parent → child ─────────────────────────────────────────────
    const { error: linkError } = await supabase
      .from("parent_children")
      .insert({ parent_id, child_id: childId });

    if (linkError) {
      console.error("Failed to link parent/child:", linkError);
    }

    // ── 4. Create default practice settings ───────────────────────────────
    await supabase.from("child_practice_settings").insert({
      child_id: childId,
    });

    return new Response(
      JSON.stringify({ success: true, child_id: childId, email }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("create-child-account error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
    });
  }
});
