# Spellasaurus 🦕

A fun, AI-powered spelling app for kids built with **Flutter** and **Supabase**.

---

## Getting Started

### 1. Supabase Setup

1. Create a project at supabase.com
2. Run the migrations in order from supabase/migrations/
3. Create a Storage bucket called **word-audio** and set it to public
4. Deploy the Edge Functions:
   `supabase functions deploy generate-word-content`
   `supabase functions deploy create-child-account`
5. Set secrets: `supabase secrets set OPENAI_API_KEY=sk-...`

### 2. Flutter Setup

Run the app with dart-define flags:

`flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key`

### 3. Generate freezed models

`dart run build_runner build --delete-conflicting-outputs`

Run this any time you modify a model in lib/shared/models/.

---
### RUN

`flutter run -d chrome --dart-define-from-file=.env.json`

## Roles

| Role | What they do |
|------|-------------|
| school_admin | Manages schools, classes, teachers |
| teacher | Creates spelling sets and words for their classes |
| parent | Adds children, creates personal lists, configures practice settings |
| child | Practises spelling with audio, descriptions, and example sentences |

## Practice Settings (per child, set by parent)

- Play word aloud (OpenAI TTS audio)
- Show AI description
- Show AI example sentence

## AI Content Generation

When a word is saved, the generate-word-content Edge Function calls GPT-4o for
an age-appropriate definition and example sentence, then calls OpenAI TTS to
generate audio, uploads it to Supabase Storage, and patches the spelling_words row.
