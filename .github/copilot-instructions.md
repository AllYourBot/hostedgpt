# HostedGPT Repository Instructions for GitHub Copilot

These instructions give Copilot essential, reusable context about this Rails application so it proposes accurate, idiomatic changes. Keep responses concise, respect existing patterns, and avoid speculative rewrites.

## Project Overview
HostedGPT is a Ruby on Rails 8.1 application providing a multi‑provider conversational AI UI (OpenAI, Anthropic, Groq, Google Gemini, others via OpenAI-compatible APIs). Users can:
- Create assistants bound to language models
- Chat with streaming responses (ActionCable)
- Switch models/providers mid conversation
- Upload and attach images/files (Active Storage; can use Postgres or Cloudflare R2)
- Use tool/function calling (provider permitting)
- Authenticate via password, Google, Microsoft Graph, or HTTP header (feature flags)

## High-Level Architecture
- Rails MVC + Hotwire (Turbo + Stimulus), Tailwind for styling.
- Background job queue: SolidQueue (runs in Puma with `RUN_SOLID_QUEUE_IN_PUMA=true`).
- Streaming tokens: ActionCable (PostgreSQL enhanced adapter).
- AI abstraction: `app/services/ai_backend/ruby_llm.rb` (`AIBackend::RubyLLM`) is the transport for every chat provider identity, riding the `ruby_llm` gem. Per-provider facts and policy live in `app/services/ai_backend/policy/` — one PORO class per identity (OpenAI, Anthropic, Gemini, Groq, OpenRouter). A service's provider identity (`APIService#provider_identity`: driver plus canonical URL for openai-dialect vendors) resolves its policy class and dispatch: `APIService#ai_backend` returns `AIBackend::RubyLLM` for every chat identity and `nil` for identities RubyLLM can't serve (brave, or a nil driver).
- Dynamic model & assistant provisioning: YAML seeds (`models.yml`, `assistants.yml`) imported per user on registration (`User::Registerable`).
- Feature flags & settings: `config/options.yml` accessed through `Feature.*` / `Setting.*` helpers.
- Message flow: `MessagesController` creates user messages; async job fetches assistant reply; streaming handled in the unified transport service.
- Soft deletion pattern: `deleted_at` timestamp + scopes (`not_deleted`).

## Key Directories / Files
- `app/models/api_service.rb` – per-user service endpoints & tokens
- `app/models/language_model.rb` – model metadata, cost, capabilities
- `app/models/assistant.rb` – wraps persona + linked language model
- `app/services/ai_backend/` – provider integrations & tool handling
- `models.yml` / `assistants.yml` – declarative seed definitions
- `config/options.yml` – feature flags & environment-driven settings
- `config/routes.rb` – conversational + settings routes
- `app/jobs/` – async tasks (e.g., auto titling conversations, AI reply fetch)
- `test/` – Minitest (system + unit); some provider calls mocked

## Supported Providers & Notes
OpenAI, Anthropic, Groq (OpenAI-compatible), Google Gemini, OpenRouter. Provider selection logic: `APIService#ai_backend` (identity → `AIBackend::RubyLLM`, or `nil` for identities RubyLLM can't serve). Tools/function calling gated by `language_model.supports_tools?` (Groq's denial is pinned in `AIBackend::Policy::Groq.supports_tools?`).

## Adding a New AI Provider (Guideline)
1. Add a base URL constant and map it in `APIService#provider_identity`.
2. Add an `AIBackend::Policy::<NewProvider>` class and register it in `AIBackend::Policy::POLICY_CLASSES` — the policy class owns `key_error_message`, `billing_url`, display name, and tool policy. RubyLLM usually speaks the provider natively, or via the openai-compatible path with a base-URL override; add provider-specific transport bits (e.g. header injection) only when needed.
3. Add default models to `models.yml`.
4. Extend seeding (user registration hook) if you want automatic creation.
5. Add minimal tests: service connectivity test + message generation path, stubbed through `TestClient::RubyLLM`.

## Adding / Modifying Language Models
Edit `models.yml`. Fields:
- `api_name`, `name`, `supports_images`, `supports_tools`, `supports_system_message`, `input_token_cost_cents`, `output_token_cost_cents`, `best`.
Changes apply via: `rails models:import` or on server restart / user creation. Keep costs as string decimals. Avoid removing active models without soft-deleting related assistants.

## Feature Flags (Selected)
Access via `Feature.flag_name?`:
- `registration`, `default_llm_keys`, `cloudflare_storage`, `google_tools`, `password_authentication`, `google_authentication`, `microsoft_graph_authentication`, `http_header_authentication`, `voice`, `default_to_voice`, `email`, `password_reset_email`.
Settings via `Setting.*` (default tokens, Cloudflare creds, SMTP/Postmark config, OAuth client IDs, header auth names).

## Conventions
- Prefer service objects / POROs in `app/services` for provider logic.
- Keep controllers lean; heavy logic belongs in backends or models.
- Use soft delete (`deleted_at`) instead of destroying dependent models where historical integrity matters.
- Stream responses incrementally; accumulate chunks on `@stream_response_text` then persist once finished.
- Avoid introducing callbacks unless clearly lifecycle-bound; prefer explicit orchestration in jobs.
- Tests: Minitest style; place shared helpers in `test/support/`.

## Testing Guidance
- For provider tests, stub network classes (see `test/support/test_client/ruby_llm.rb`) instead of recording cassettes.
- System tests run outside Docker CI (headless browser). Keep selectors semantic (`data-testid` if needed – add sparingly).
- When changing streaming logic, add a test ensuring partial token emission order and final persistence.

## Performance / Reliability
- Token counting stored per message (`input_token_count`, `output_token_count`). Update only when usage data present to avoid stale numbers.
- Long responses can be cancelled; ensure backend rescues and raises `GetNextAIMessageJob::ResponseCancelled` appropriately.
- Keep DB queries scoped by user (`for_user`) to enforce multi-tenancy boundary.

## Security / Privacy
- API tokens stored encrypted (`encrypts :token`). Never log raw tokens; length-only logging is acceptable.
- Validate URLs for `APIService#url` and normalize whitespace.
- Header authentication: treat configured headers as trusted; do not reuse them for untrusted input.

## Making Changes
1. If altering data shape (models), add a migration and update related YAML seeds if needed.
2. Run full test suite locally (`rails test`). For streaming or job changes, manually exercise a conversation.
3. Keep README deploy sections intact; do not duplicate that content here.
4. For new feature flags: add ENV reference in `config/options.yml`, document toggling logic, ensure safe defaults (usually `false`).

## Avoid
- Large speculative refactors across AI backend classes without incremental tests.
- Introducing provider-specific conditionals in controllers (encapsulate in backend layer).
- Hard-coding model lists in code (use YAML + import tasks).

## When Unsure
Inspect `app/services/ai_backend/ruby_llm.rb` (transport integration points: `configure_context`, `build_chat`, `test_execute`) and `app/services/ai_backend/policy/` (per-identity facts), mirroring an existing identity's structure.

## Quick Reference Snippets
- Import models for all users: `rails models:import`.
- Export models: `rails models:export[tmp/models.json]`.
- Run queue in Puma (prod single-process deploys): `RUN_SOLID_QUEUE_IN_PUMA=true`.

## Style
- Follow Standard/RuboCop Rails defaults already configured.
- Use early returns over nested conditionals.
- Keep methods < ~25 lines where practical in service classes.

## Output Expectations For Copilot
When asked to extend provider support or add a model:
- Provide migration (if schema changes), service class skeleton, test stub, and README delta (if user-facing).
When asked for configuration help:
- Reference feature flag name & corresponding ENV in `options.yml`.
When generating tests:
- Prefer focused unit tests; mock external clients; assert persisted record state & streaming accumulation.

End of instructions.
