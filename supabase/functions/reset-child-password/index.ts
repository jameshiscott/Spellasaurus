// Spellasaurus — Edge Function: reset-child-password
// Called by a parent to reset the password of one of their child accounts.
// Uses the service role key so it can call admin.updateUserById().

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // ── Verify the caller is authenticated ──────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(
      JSON.stringify({ error: "Missing or invalid Authorization header" }),
      {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  const callerClient = createClient(
    SUPABASE_URL,
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    }
  );
  const {
    data: { user: callerUser },
    error: callerErr,
  } = await callerClient.auth.getUser();
  if (callerErr || !callerUser) {
    return new Response(
      JSON.stringify({
        error: "Invalid or expired session. Please log in again.",
      }),
      {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  try {
    const { child_id, new_password } = await req.json();

    if (!child_id || !new_password) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: child_id, new_password" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (new_password.length < 8) {
      return new Response(
        JSON.stringify({ error: "Password must be at least 8 characters" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // ── Verify caller is actually the parent of this child ────────────────
    const { data: link, error: linkErr } = await supabase
      .from("parent_children")
      .select("parent_id")
      .eq("parent_id", callerUser.id)
      .eq("child_id", child_id)
      .maybeSingle();

    if (linkErr || !link) {
      return new Response(
        JSON.stringify({ error: "Forbidden: you are not this child's parent." }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ── Update the child's password ───────────────────────────────────────
    const { error: updateErr } = await supabase.auth.admin.updateUserById(
      child_id,
      { password: new_password }
    );

    if (updateErr) {
      return new Response(
        JSON.stringify({ error: updateErr.message }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("reset-child-password error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
