// Spellasaurus — Edge Function: generate-word-content
// Triggered after a spelling word is saved.
// Calls OpenAI to generate an age-appropriate description, example sentence,
// and a high-quality TTS audio file, then stores the audio in Supabase Storage.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { word_id } = await req.json();
    if (!word_id) {
      return new Response(JSON.stringify({ error: "word_id required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // ── 1. Load the word and calculate target age ──────────────────────────
    const { data: wordRow, error: wordErr } = await supabase
      .from("spelling_words")
      .select(`
        id, word, set_id,
        spelling_sets (
          id, class_id, child_id,
          classes (
            class_students (
              profiles ( date_of_birth )
            )
          ),
          profiles:child_id ( date_of_birth )
        )
      `)
      .eq("id", word_id)
      .single();

    if (wordErr || !wordRow) {
      return new Response(JSON.stringify({ error: "Word not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const word = wordRow.word as string;
    const targetAge = calculateTargetAge(wordRow);

    // ── 2. Generate description + example sentence with GPT-4o ────────────
    const gptResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o",
        max_tokens: 200,
        temperature: 0.7,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content: `You help children aged ${targetAge} years old learn to spell. 
              Respond ONLY with valid JSON. 
              Use simple, clear language appropriate for a ${targetAge}-year-old child.`,
          },
          {
            role: "user",
            content: `Give me a definition and an example sentence for the word "${word}".
              IMPORTANT RULES:
              1. The "description" must NOT contain the word "${word}" exactly as written. Describe what it means without using the word itself.
              2. The "example_sentence" must use the word "${word}" exactly as written (do NOT use a different form, root, or variation of the word). Replace that exact word with "_______" (seven underscores) in the sentence.
              Respond with exactly this JSON shape:
              {
                "description": "...",
                "example_sentence": "A sentence using _______ where the word would go."
              }`,
          },
        ],
      }),
    });

    const gptData = await gptResponse.json();
    let description = "";
    let exampleSentence = "";

    const rawContent = gptData.choices?.[0]?.message?.content as string ?? "";
    const parsed = JSON.parse(rawContent);
    description = parsed.description ?? "";
    exampleSentence = parsed.example_sentence ?? "";

    if (!description || !exampleSentence) {
      throw new Error("GPT response missing description or example_sentence");
    }

    // Safety net: ensure the exact word never appears in description or example sentence
    const escapedWord = word.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const wordRegex = new RegExp(`\\b${escapedWord}\\b`, "gi");
    description = description.replace(wordRegex, "_______");
    exampleSentence = exampleSentence.replace(wordRegex, "_______");

    // ── 3. Generate TTS audio with OpenAI tts-1-hd ────────────────────────
    const ttsResponse = await fetch("https://api.openai.com/v1/audio/speech", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "tts-1-hd",
        voice: "nova",
        input: word,
        response_format: "mp3",
      }),
    });

    if (!ttsResponse.ok) {
      throw new Error(`TTS failed: ${ttsResponse.statusText}`);
    }

    const audioBuffer = await ttsResponse.arrayBuffer();
    const audioFileName = `words/${word_id}.mp3`;

    // ── 4. Upload audio to Supabase Storage ───────────────────────────────
    const { error: uploadError } = await supabase.storage
      .from("word-audio")
      .upload(audioFileName, audioBuffer, {
        contentType: "audio/mpeg",
        upsert: true,
      });

    if (uploadError) {
      throw new Error(`Storage upload failed: ${uploadError.message}`);
    }

    const { data: publicUrlData } = supabase.storage
      .from("word-audio")
      .getPublicUrl(audioFileName);

    const audioUrl = publicUrlData.publicUrl;

    // ── 5. Patch the spelling_words row ───────────────────────────────────
    const { error: updateError } = await supabase
      .from("spelling_words")
      .update({
        ai_description: description,
        ai_example_sentence: exampleSentence,
        audio_url: audioUrl,
        ai_generated_at: new Date().toISOString(),
      })
      .eq("id", word_id);

    if (updateError) {
      throw new Error(`Update failed: ${updateError.message}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        word,
        audio_url: audioUrl,
        description,
        example_sentence: exampleSentence,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("generate-word-content error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

function calculateTargetAge(wordRow: any): number {
  const set = wordRow.spelling_sets;
  if (!set) return 8; // default

  // Personal set — use the child's DOB
  if (set.child_id && set.profiles?.date_of_birth) {
    return ageFromDob(set.profiles.date_of_birth);
  }

  // Class set — average age of enrolled students
  const classStudents = set.classes?.class_students ?? [];
  const dobs: string[] = classStudents
    .map((cs: any) => cs.profiles?.date_of_birth)
    .filter(Boolean);

  if (dobs.length === 0) return 8;

  const totalAge = dobs.reduce(
    (sum: number, dob: string) => sum + ageFromDob(dob),
    0
  );
  return Math.round(totalAge / dobs.length);
}

function ageFromDob(dob: string): number {
  const birth = new Date(dob);
  const now = new Date();
  let age = now.getFullYear() - birth.getFullYear();
  const m = now.getMonth() - birth.getMonth();
  if (m < 0 || (m === 0 && now.getDate() < birth.getDate())) age--;
  return Math.max(4, Math.min(16, age)); // clamp to sensible school range
}
