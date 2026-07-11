---
artifact_contract: ce-unified-plan/v1
artifact_readiness: implementation-ready
product_contract_source: ce-plan-bootstrap
execution: code
title: "PR Quality Pass: Improve RubyLLM Migration"
date: 2026-07-10
plan_depth: deep
---

# PR Quality Pass: Improve RubyLLM Migration

## Product Contract

### Summary

Strengthen the existing `add-in-rubyllm-ai` PR by simplifying the RubyLLM integration, removing leftover provider-specific code, hardening tests, cleaning error handling, and updating developer documentation — all while preserving user-facing behavior and the existing green test suite.

### Problem Frame

The PR successfully replaced OpenAI/Anthropic/Gemini provider gems with `ruby_llm` and unified `AIBackend`. With the suite green (633 runs, 0 failures), the remaining work is quality: cleaning up accidental complexity and improving the implementation before final review/merge. Concrete issues observed:

- `AIBackend` still builds per-provider content parts for images/PDFs, reproducing the kind of provider-specific formatting RubyLLM was meant to absorb.
- `AIBackend::Tools` retains dead `NotImplementedError` methods from the old subclass architecture.
- Job tests exist as three near-identical provider-specific files (`get_next_ai_message_job_openai_test.rb`, `_anthropic_test.rb`, `_gemini_test.rb`) that no longer match the unified backend.
- `get_next_ai_message_job.rb` overloads `Faraday::ParsingError` to mean "blank response" and rescues known RubyLLM errors alongside a very broad `rescue => e` fallback.
- `AIBackend` has `Rails.env.test?` branches inside production logic to swap in `TestChat`.
- Developer docs (`.github/copilot-instructions.md`) still describe the pre-unification `AIBackend::<Provider>` architecture.

### Requirements

- **R1:** Remove or consolidate provider-specific code/tests that are no longer needed after unification.
- **R2:** Simplify message construction so RubyLLM handles provider-specific image/PDF/attachment encoding wherever possible.
- **R3:** Improve `GetNextAIMessageJob` error handling — explicit blank-response semantics, cleaner RubyLLM error mapping, and safer logging of tokens.
- **R4:** Strengthen test coverage and assertions, especially for tool registration, streaming, and error paths.
- **R5:** Remove `Rails.env.test?` branching from production backend logic.
- **R6:** Update developer-facing documentation to reflect the unified RubyLLM backend.

### Scope Boundaries

#### In scope
- `app/services/ai_backend.rb` and `app/services/ai_backend/*.rb`
- `app/jobs/get_next_ai_message_job.rb` and `app/jobs/autotitle_conversation_job.rb` (minor RubyLLM-param cleanups)
- `app/services/toolbox/image.rb` if there are leftover duplication opportunities
- Test files under `test/services/ai_backend/`, `test/jobs/`, `test/controllers/settings/`
- `.github/copilot-instructions.md`

#### Out of scope / deferred
- Adding new LLM providers to the enum.
- Rewriting `Toolbox` reflection DSL or replacing it with `RubyLLM::Tool` classes.
- Changing persistence/Message model or ActionCable broadcasting logic.
- Migrating the model registry (`models.yml`) to RubyLLM's registry.
- Production performance/load testing.

## Planning Contract

### Key Technical Decisions

#### D1: Let RubyLLM format multimodal attachments
Replace the per-driver `build_image_content`, `text_part`, and raw-content-part assembly with RubyLLM's `Content` API (e.g., `chat.add_message(role: :user, content: message.content_text, with: message.documents)` or `RubyLLM::Content.new(text, documents)`). RubyLLM's `Attachment` class natively supports `ActiveStorage` attachments and provider-specific encoding.

**Rationale:** Eliminates the last provider-specific branching inside `AIBackend`, reduces code, and centralizes format evolution inside RubyLLM.

**Risk:** Active Storage URL vs. base64 behavior changes for OpenAI. Mitigated by existing image/PDF tests plus a manual smoke test.

#### D2: Remove provider-specific job test files and consolidate coverage
Delete `test/jobs/get_next_ai_message_job_openai_test.rb`, `test/jobs/get_next_ai_message_job_anthropic_test.rb`, and `test/jobs/get_next_ai_message_job_gemini_test.rb`. Move their unique assertions (blank-key messages for OpenAI/Anthropic/Gemini, blank response) into the provider-agnostic `test/jobs/get_next_ai_message_job_test.rb`.

**Rationale:** With a single `AIBackend`, provider-specific files duplicate the same job flow. Consolidation makes the test surface match the architecture.

**Risk:** Losing driver-specific message assertions. Mitigated by preserving per-provider key-blank tests in the unified file.

#### D3: Introduce a backend-level blank-response error class
Define `AIBackend::BlankResponseError < StandardError` and raise it from `AIBackend#stream_next_conversation_message` when no content was streamed. Update `GetNextAIMessageJob` to rescue the new class instead of `Faraday::ParsingError`.

**Rationale:** `Faraday::ParsingError` is an implementation detail and no longer describes the actual failure. An explicit error makes intent clear and removes an unnecessary dependency from the job contract.

#### D4: Inject the chat factory rather than branching on `Rails.env.test?`
Replace inline `Rails.env.test?` checks in `AIBackend` with a configurable chat factory (e.g., a class attribute `AIBackend.chat_factory` that defaults to `RubyLLM.context.chat`). In `test_helper.rb` (or a Rails initializer block for test only), assign `AIBackend.chat_factory = ->(*args) { TestChat.new(*args) }`.

**Rationale:** Production code should not know about test doubles. This follows the existing service-object convention and makes `AIBackend` easier to test in isolation.

**Risk:** Touches `TestChat` shape and how the production constructor is called. Mitigated by keeping `TestChat` interface-compatible and adding a characterization test around factory injection.

#### D5: Keep `InterceptedTool` but simplify it and remove dead methods from `AIBackend::Tools`
`AIBackend::Tools` still exposes abstract `format_parallel_tool_calls` and `parallel_tool_calls` methods that raise `NotImplementedError`; delete them. Keep the `InterceptedTool` wrapper but consider whether it can delegate name/description/schema more directly from `Toolbox.tools` definitions.

**Rationale:** Dead abstract methods are leftover from the subclass architecture. The wrapper itself is still the cleanest way to halt RubyLLM's automatic tool execution while surfacing the requested tool calls.

### Assumptions

- RubyLLM v1.16.0's `Attachment`/`Content` APIs accept Active Storage attachments and produce equivalent or better payloads for OpenAI, Anthropic, and Gemini.
- The existing test fixtures provide enough message/document data to verify multimodal behavior after refactoring.
- No production behavior changes are intended; only internal quality improvements.

## Implementation Units

### U1: Simplify multimodal message formatting

**Files:**
- `app/services/ai_backend.rb`
- `test/services/ai_backend_test.rb`

**Description:**
Replace the driver-specific content-part builders with RubyLLM's content abstraction.

1. In `app/services/ai_backend.rb`:
   - Remove the `driver` parameter from `build_multimodal_message` helpers.
   - For user messages with documents, build a `RubyLLM::Content` (or use `with:` attachments) combining the message text and `message.documents`. Extracted PDF text can remain as part of the text.
   - Delete `text_part` and `build_image_content` methods.
   - Remove the `driver` local variable threading from `build_multimodal_message`.

2. Keep `build_assistant_with_tool_calls_message` and tool-role message formatting unchanged in this unit.

**Test file:** `test/services/ai_backend_test.rb`

**Test scenarios (add or update):**
- Messages with image attachments create a `RubyLLM::Content` object (not a per-driver hash) for OpenAI, Anthropic, and Gemini drivers.
- Messages with PDFs still include extracted PDF text and the PDF attachment.
- Existing image/pdf attachments fixture tests still pass.
- `preceding_conversation_messages` never returns the old `{ type: "image", source: ... }` or `{ inline_data: ... }` shapes.

### U2: Clean up tool-call abstraction and dead module code

**Files:**
- `app/services/ai_backend.rb`
- `app/services/ai_backend/tools.rb`
- `test/services/ai_backend/tools_test.rb`
- `test/services/ai_backend_test.rb`

**Description:**
Remove leftover abstraction damage and clarify the tool-interception contract.

1. In `app/services/ai_backend/tools.rb`:
   - Delete `format_parallel_tool_calls` and `parallel_tool_calls` methods (they are `NotImplementedError` dead code).
   - Keep `get_tool_messages_by_calling` unchanged; it already converts RubyLLM tool calls into persisted tool messages correctly.

2. In `app/services/ai_backend.rb`:
   - Review `InterceptedTool` for simplicity. Ensure `name`, `description`, and `params_schema` pull cleanly from the Toolbox definition.
   - Keep the `ToolCallIntercepted` exception mechanism (proven in tests); do not switch to automatic execution.

**Test file:** `test/services/ai_backend/tools_test.rb`

**Test scenarios:**
- `get_tool_messages_by_calling` still executes tools and returns tool-role messages.
- Calling an invalid/failing tool returns a structured error message.
- `format_parallel_tool_calls` and `parallel_tool_calls` no longer exist on `AIBackend`.
- When tools are registered, the `TestChat` mock records the expected tool definitions.

### U3: Consolidate provider-specific job tests

**Files:**
- `test/jobs/get_next_ai_message_job_openai_test.rb` → delete
- `test/jobs/get_next_ai_message_job_anthropic_test.rb` → delete
- `test/jobs/get_next_ai_message_job_gemini_test.rb` → delete
- `test/jobs/get_next_ai_message_job_test.rb` → expand

**Description:**
Delete the near-duplicate provider files and keep one provider-agnostic test class. Preserve the unique assertions about blank-key wording by using the existing fixtures (`keith_openai_service`, `keith_anthropic_service`, `keith_groq_service` / Gemini conversation).

**Test file:** `test/jobs/get_next_ai_message_job_test.rb`

**Test scenarios (moved/added):**
- Populates the latest assistant message (provider-agnostic).
- Creates tool response messages and a follow-up assistant message when the model returns tool calls.
- Returns early for invalid message/assistant IDs, already-populated messages, and newer user replies.
- Blank OpenAI key shows the OpenAI-specific key prompt.
- Blank Anthropic key shows the Anthropic-specific key prompt.
- Blank Gemini key shows the generic Gemini configuration error.
- Empty response shows the blank-response message.

### U4: Harden job error handling

**Files:**
- `app/services/ai_backend.rb`
- `app/jobs/get_next_ai_message_job.rb`
- `test/jobs/get_next_ai_message_job_test.rb`

**Description:**
Make blank responses and RubyLLM errors explicit and safe.

1. In `app/services/ai_backend.rb`:
   - Define `AIBackend::BlankResponseError < StandardError`.
   - Raise `BlankResponseError` instead of `Faraday::ParsingError` when `@stream_response_text` is blank after streaming.

2. In `app/jobs/get_next_ai_message_job.rb`:
   - Replace the two `Faraday::ParsingError` rescues with `AIBackend::BlankResponseError`.
   - Keep RubyLLM-specific rescues (`ConfigurationError`, `UnauthorizedError`, `RateLimitError`, `PaymentRequiredError`, `ServerError`, `ServiceUnavailableError`, `OverloadedError`, `BadRequestError`, `ContextLengthExceededError`, `ForbiddenError`).
   - In the generic `rescue => e` block, confirm API-key redaction handles both `sk-...` and any other token-like strings (e.g., Anthropic keys); at minimum, preserve the current `sk-` redaction.

**Test file:** `test/jobs/get_next_ai_message_job_test.rb`

**Test scenarios:**
- `AIBackend::BlankResponseError` displays the blank-response message.
- `RubyLLM::RateLimitError` displays the billing error with the right provider URL.
- `RubyLLM::PaymentRequiredError` displays the billing error.
- `RubyLLM::ServerError`/`ServiceUnavailableError`/`OverloadedError` display the generic blank/try-again message.
- `RubyLLM::BadRequestError` displays the unexpected-error message.
- Generic third attempt logs no raw API keys.

### U5: Remove `Rails.env.test?` branching from production backend logic

**Files:**
- `app/services/ai_backend.rb`
- `test/support/test_chat.rb`
- `test/test_helper.rb` (or a new `config/initializers/ruby_llm.rb` test-only block)

**Description:**
Introduce a configurable chat factory so `AIBackend` no longer switches on environment.

1. In `app/services/ai_backend.rb`:
   - Add a class attribute: `class_attribute :chat_factory, default: ->(context, model, provider, api_name) { context.chat(model: api_name, provider: provider, assume_model_exists: true) }` (or equivalent).
   - Replace the `Rails.env.test?` branch in `build_chat` with `AIBackend.chat_factory.call(context, ...)`.
   - Replace the `Rails.env.test?` branches in `get_oneoff_message`, `stream_next_conversation_message`, and `test_execute` with calls to the same factory, or move test-short-circuit behavior into `TestChat` itself.

2. In test support:
   - Set `AIBackend.chat_factory = ->(...) { TestChat.new(...) }` during test setup.
   - Ensure `TestChat` still implements `with_instructions`, `with_params`, `with_tools`, `add_message`, `complete`, and `ask`.

**Test file:** `test/services/ai_backend_test.rb`

**Test scenarios:**
- `build_chat` returns a `TestChat` instance in tests without checking `Rails.env.test?`.
- No `Rails.env.test?` references remain in `app/services/ai_backend.rb` or `app/services/ai_backend/*.rb`.
- Production factory would create a real `RubyLLM::Chat` when configured (this can be a unit-style assertion on the factory lambda).

### U6: Strengthen assertions and add missing coverage

**Files:**
- `test/services/ai_backend_test.rb`
- `test/services/toolbox/image_test.rb`
- `test/controllers/settings/api_services_controller_test.rb`
- `test/controllers/settings/language_models_controller_test.rb`

**Description:**
Fix tests that currently run without assertions and add coverage for edge cases introduced by the migration.

1. In `test/services/ai_backend_test.rb`:
   - The tests `"tools only passed when supported by the language model"` and `"tools not passed when not supported by the language model"` currently have no assertions. Add assertions that `TestChat#tools` is populated/not populated.
   - Add a test for `test_api_service` with a blank token returning the expected error string.
   - Add a test for `test_language_model` returning an error when RubyLLM raises `UnauthorizedError`.
   - Add a streaming test asserting chunk order matches what RubyLLM yields and token counts are written.

2. In `test/services/toolbox/image_test.rb`:
   - Add a test that image generation raises a clear error when no OpenAI service/token exists.

3. In controller tests:
   - Ensure the service/language-model connectivity tests still pass with `TestChat`.

**Test scenarios:**
- Tool registration is/no-op based on `supports_tools?`.
- `test_api_service` blank token returns `"Error: API key (token) is blank"`.
- `test_language_model` handles `RubyLLM::UnauthorizedError`.
- Streaming writes `input_token_count`/`output_token_count` when chunks include token info.
- Image generation without an OpenAI key raises a user-facing message about configuring an OpenAI API key.

### U7: Update autotitle params to be provider-agnostic where RubyLLM permits

**Files:**
- `app/jobs/autotitle_conversation_job.rb`
- `test/jobs/autotitle_conversation_job_test.rb`

**Description:**
Try collapsing the `case driver` params block. RubyLLM's providers may translate `response_format: { type: "json_object" }` internally for Gemini. If tests/manual checks show it does, replace the explicit Gemini branch with the OpenAI-style JSON params and let RubyLLM translate.

If RubyLLM does not translate for Gemini, keep the branch and add a code comment explaining why.

**Test scenarios:**
- Autotitle still works for OpenAI and Anthropic drivers.
- Autotitle works for Gemini driver.
- Non-JSON response fallback still extracts topic with regex.

### U8: Update developer documentation

**Files:**
- `.github/copilot-instructions.md`
- `README.md`

**Description:**
1. In `.github/copilot-instructions.md`:
   - Update the "AI abstraction" bullet from `AIBackend::<Provider>` classes to a single unified `AIBackend` using `ruby_llm`.
    - Update the "Adding a New AI Provider" guideline to reference `APIService.driver`, the unified backend, and `assume_model_exists: true`.
   - Update the testing note from "OpenAI test client approach" to the `TestChat` factory.

2. In `README.md`:
   - Ensure no references to provider-specific gems (`ruby-openai`, `ruby-anthropic`, `gemini-ai`, `tiktoken_ruby`).
   - Optionally add a short note that HostedGPT now uses RubyLLM for unified provider support.

**Verification:**
- `grep -R "AIBackend::" .github/` returns no provider-specific references.
- `grep -R "ruby-openai\|ruby-anthropic\|gemini-ai\|tiktoken" README.md .github/` returns no results.

### U9: Gem/dependency and require hygiene

**Files:**
- `Gemfile`
- `Gemfile.lock`
- `config/initializers/ruby_llm.rb`

**Description:**
Verify the migration cleanup is complete.

1. Confirm `ruby-openai`, `ruby-anthropic`, `gemini-ai`, and `tiktoken_ruby` are absent from `Gemfile` and `Gemfile.lock`.
2. Confirm no `require "openai"/"anthropic"/"gemini"/"tiktoken"` exist in `app/`/`lib/`/`config/`.
3. Review `config/initializers/ruby_llm.rb` to ensure it only sets global config (logger, timeout, log level) and that dummy keys are appropriate for test/dev. Consider guarding prod boot if real keys are missing (out of scope unless trivial).

**Verification:**
- `bundle install` succeeds.
- `grep -rE "require ['\"](openai|anthropic|gemini|tiktoken)['\"]" app/ lib/ config/` returns nothing.
- `grep -E "ruby-openai|ruby-anthropic|gemini-ai|tiktoken_ruby" Gemfile Gemfile.lock` returns nothing.

## Test Scenarios and Verification Steps

### Automated verification
1. Run the focused backend suite: `bin/rails test test/services/ai_backend_test.rb test/services/ai_backend/tools_test.rb test/services/ai_backend/memory_test.rb`
2. Run the job suite: `bin/rails test test/jobs/get_next_ai_message_job_test.rb test/jobs/autotitle_conversation_job_test.rb`
3. Run controller connectivity tests: `bin/rails test test/controllers/settings/api_services_controller_test.rb test/controllers/settings/language_models_controller_test.rb`
4. Run the full suite: `bin/rails test`
5. Run static analysis: `bundle exec standardrb`

### Manual smoke verification
Perform one manual pass per provider (OpenAI, Anthropic, Gemini if keys available; Groq as OpenAI-compatible):

1. **Text streaming:** Start a new conversation, send a message, verify response streams.
2. **Tool calling:** Ask for weather in a real city. Verify tool message appears, then assistant final reply.
3. **Image attachment:** Attach an image and ask about it. Verify no raw provider errors.
4. **PDF attachment:** Attach a PDF and ask a question. Verify extracted text is used.
5. **Image generation:** Ask the assistant to generate an image (OpenAI key required). Verify image is created and attached.
6. **Error cases:** Remove the API key, start a conversation, verify the friendly key-error message.

### Regression checklist
- Token counts populate when available.
- Conversation auto-titling works for each driver used.
- Response cancellation still works.
- Switching assistants/models mid-conversation still works.

## Risks and Dependencies

| Risk | Impact | Mitigation |
|------|--------|------------|
| RubyLLM's `Content`/`Attachment` payload for images differs subtly from the current manual payload (e.g., URL vs. base64). | High on user experience for image-in-message | Keep existing image fixtures and add driver-specific assertion coverage; run manual smoke test with each provider. |
| Removing provider-specific job tests without fully preserving assertions hides a provider-specific error-message regression. | Medium | Explicitly map the three blank-key tests into the unified job test file before deleting the old files. |
| Refactoring `Rails.env.test?` branches touches the production chat builder and the test double boundary. | Medium | Make `TestChat` interface-compatible first; add a factory-injection test; keep change isolated to `AIBackend`. |
| Switching blank-response signal from `Faraday::ParsingError` to a custom error could affect other code that catches `Faraday::ParsingError`. | Low | Search the entire codebase for `Faraday::ParsingError` rescues before changing. |
| RubyLLM may not translate `response_format` for Gemini autotitle. | Low | Revert to explicit branch if manual/Gemini test fails. |

### Dependencies
- `ruby_llm ~> 1.16` is already added and stable.
- Active Storage is already configured for documents.
- Test suite is currently green; improvements should be made incrementally to keep it green.

## Existing Patterns to Follow

- `AIBackend` is a plain Ruby service object in `app/services/`.
- `TestChat` is the single test double under `test/support/`; keep it interface-stable.
- Multi-tenancy is enforced via `Current.user` and per-user `APIService` records.
- Error messages are set directly onto `message.content_text` and broadcast.
- `Standard`/RuboCop Rails style is configured in `.rubocop.yml`.
