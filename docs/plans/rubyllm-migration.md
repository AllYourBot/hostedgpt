---
artifact_contract: ce-unified-plan/v1
artifact_readiness: implementation-ready
product_contract_source: ce-plan-bootstrap
execution: code
title: "Replace multi-provider LLM infrastructure with RubyLLM"
date: 2026-07-10
plan_depth: deep
---

# Replace multi-provider LLM infrastructure with RubyLLM

## Problem Frame

HostedGPT currently uses three separate provider-specific gems (`ruby-openai`, `ruby-anthropic`, `gemini-ai`) to talk to OpenAI, Anthropic, and Google Gemini. Each has its own client class, streaming format, message format, tool-calling format, and error class. Three `AIBackend::*` classes (~560 lines total) duplicate significant per-provider logic: message formatting for images/PDFs/tool-calls, streaming handlers, tool-call normalization, and error mapping. `tiktoken_ruby` is listed in the Gemfile but unused in application code.

[RubyLLM](https://rubyllm.com) (`ruby_llm` gem, v1.16.0) provides a single unified Ruby interface across all major AI providers — same Chat API, streaming, tools, and error hierarchy whether the model is GPT, Claude, or Gemini. It handles provider-specific message formatting, streaming SSE parsing, and tool-call protocol internally. It supports custom endpoints (Groq, local models), per-request configuration contexts (multi-tenant API keys), `assume_model_exists` for unlisted models, image generation (`RubyLLM.paint`), and a unified error hierarchy (`RubyLLM::Error` subclasses).

**Goal:** Replace `ruby-openai`, `ruby-anthropic`, `gemini-ai`, and `tiktoken_ruby` with `ruby_llm`, collapsing the three `AIBackend::*` classes into a single unified backend that delegates to RubyLLM. Preserve all user-facing behavior: streaming responses via ActionCable, tool/function calling with persisted tool messages, image generation, autotitling, multi-modal (images/PDFs), per-user API keys, custom endpoints (Groq), and user-friendly error messages.

## Scope

### In scope
- Add `ruby_llm` gem and configuration initializer
- Create a single `AIBackend` implementation that uses RubyLLM's Chat API
- Adapt `preceding_conversation_messages` to use RubyLLM's `add_message` / `with:` attachment API
- Migrate tool calling to work with RubyLLM's tool system while preserving HostedGPT's persisted-tool-message architecture
- Replace `Toolbox::Image`'s direct `OpenAI::Client` usage with `RubyLLM.paint`
- Update `GetNextAIMessageJob` error handling to map `RubyLLM::Error` subclasses
- Update `AutotitleConversationJob` to use the unified backend
- Replace `TestClient::*` test stubs with RubyLLM-compatible mocks
- Remove `ruby-openai`, `ruby-anthropic`, `gemini-ai`, `tiktoken_ruby` from Gemfile
- Update all affected tests to pass

### Out of scope (deferred)
- Rails ActiveRecord `acts_as_chat` integration (RubyLLM has this, but HostedGPT has its own Message/Conversation model — not adopting RubyLLM's persistence layer)
- RubyLLM embeddings, audio transcription, moderation features
- RubyLLM Agent class (HostedGPT has its own Assistant model)
- Adding new providers beyond what's currently supported (RubyLLM supports many more, but that's a separate feature)
- Model registry migration (HostedGPT uses `models.yml`; RubyLLM has its own registry — not merging them)

## Key Decisions

### D1: Collapse three AIBackend classes into one
**Decision:** Replace `AIBackend::OpenAI`, `AIBackend::Anthropic`, `AIBackend::Gemini` with a single `AIBackend` class that uses `RubyLLM.chat`. RubyLLM handles provider differences internally.

**Rationale:** The entire point of RubyLLM is a unified interface. Keeping three classes that all delegate to the same RubyLLM API would add indirection without value. The `APIService#driver` enum (`openai`, `anthropic`, `gemini`) is still needed to tell RubyLLM which provider to route to, but the backend class itself is unified.

**Risk:** Large diff touching all three backend files. Mitigated by preserving the external interface (`stream_next_conversation_message`, `get_oneoff_message`, `test_language_model`, `test_api_service`) so `GetNextAIMessageJob` and `AutotitleConversationJob` changes are minimal.

### D2: Per-user API keys via RubyLLM contexts
**Decision:** Use `RubyLLM.context` to create isolated configurations per user-request, setting the provider API key from `APIService#effective_token` at request time. Do not use a global `RubyLLM.configure` for user keys.

**Rationale:** HostedGPT is multi-tenant — each user has their own API keys. RubyLLM's context system (`RubyLLM.context do |config| ... end`) creates an isolated configuration scope that doesn't affect global state. This maps cleanly to `APIService#effective_token`.

### D3: Tool calling — preserve HostedGPT's persisted-message architecture
**Decision:** Do NOT use RubyLLM's automatic tool execution. Instead, pass tools to RubyLLM for the model to request, but intercept tool calls from the streaming response (via `chunk.tool_calls`) and return them to `GetNextAIMessageJob` — which executes tools, persists tool messages, and re-enqueues — exactly as it does today.

**Rationale:** HostedGPT's architecture persists every tool call and tool result as a separate `Message` record, broadcasts them via ActionCable, and uses an async job loop. RubyLLM's built-in tool execution happens synchronously within a single `ask` call and doesn't persist intermediate tool messages. Adapting RubyLLM's automatic execution would require fundamental changes to the message model, the job flow, and the real-time UI. Intercepting tool calls from the stream and handling them externally preserves the existing architecture while still using RubyLLM for the LLM communication.

**Implementation approach:** Use RubyLLM's `with_tools` to register tools (so the model knows what's available and returns structured tool calls), but use a tool-call interception mechanism. The cleanest path is to register tools that raise a special exception when executed, which halts RubyLLM's automatic execution and surfaces the tool call to our code. Alternatively, parse `chunk.tool_calls` from the stream and use `halt` or an exception to stop automatic execution. This needs validation during implementation — the exact mechanism depends on RubyLLM's internals for stopping after a tool call.

### D4: Message formatting via RubyLLM's add_message and with: parameter
**Decision:** Use RubyLLM's `chat.add_message(role:, content:)` for conversation history and `with:` parameter for file attachments. RubyLLM handles provider-specific encoding (base64 for Anthropic, image_url for OpenAI, inline_data for Gemini) internally.

**Rationale:** The three `preceding_conversation_messages` methods (~250 lines total) exist solely to format messages differently per provider. RubyLLM normalizes this — you pass the same content regardless of provider. For images, RubyLLM's `with: [file_path]` or `Content::Raw` blocks handle encoding. For PDFs, RubyLLM's file detection handles `.pdf` files. For tool calls/results, RubyLLM's `add_message` with tool role handles formatting.

### D5: Keep the Toolbox reflection system, adapt output to RubyLLM::Tool
**Decision:** Wrap existing `Toolbox::*` classes as `RubyLLM::Tool` subclasses or create an adapter that converts `Toolbox.tools` (OpenAI function format) to RubyLLM tool definitions. The existing `Toolbox.call` dispatch mechanism is preserved for executing tools.

**Rationale:** The `Toolbox` system uses Ruby reflection to auto-generate function schemas from method parameter names (e.g., `name_s` → string param "name"). Rewriting all tools as `RubyLLM::Tool` classes would be a large change with no user-facing benefit. Instead, create an adapter that converts `Toolbox.tools` output to RubyLLM's tool registration format, and keep `Toolbox.call` for execution. RubyLLM's manual JSON Schema approach for tools (`params type: "object", properties: {...}`) can accept the same schema format that `Toolbox` already produces.

### D6: Image generation via RubyLLM.paint
**Decision:** Replace `Toolbox::Image`'s direct `OpenAI::Client.new(...).images.generate(...)` call with `RubyLLM.paint`. This requires the user's OpenAI API key to be configured in the RubyLLM context.

**Rationale:** RubyLLM's `paint` method provides a unified image generation API. This removes the last direct dependency on `OpenAI::Client`.

## Dependencies & Sequencing

```
U1 (Gem + Config) → U2 (Unified Backend) → U3 (Message Formatting)
                  → U4 (Tool Calling) → U5 (Image Generation)
                  → U6 (Error Handling) → U7 (Autotitle Job)
                  → U8 (Tests) → U9 (Cleanup)
```

U1 must land first. U2 depends on U1. U3-U7 depend on U2 and can be developed in sequence. U8 spans all units. U9 (gem removal) is last.

---

## Implementation Units

### U1: Add RubyLLM gem and configuration

**Files:**
- `Gemfile` — add `gem "ruby_llm"`, remove `ruby-openai`, `ruby-anthropic`, `gemini-ai`, `tiktoken_ruby`
- `Gemfile.lock` — regenerate via `bundle install`
- `config/initializers/ruby_llm.rb` — new initializer

**Description:**
Add the `ruby_llm` gem. Create a minimal initializer that configures the global RubyLLM settings (logger, timeout, retry) but NOT user API keys (those come per-request via `RubyLLM.context`). The initializer should set `config.logger = Rails.logger` and reasonable timeouts. Do not set `default_model` — the model is always specified per-request from `LanguageModel#api_name`.

The initializer should also handle the test environment — in test mode, no real API keys are needed because all LLM calls are stubbed. Set a dummy key to satisfy RubyLLM's configuration check.

**Test file:** `test/initializers/ruby_llm_test.rb` — verify initializer loads without error and RubyLLM is configured.

**Test scenarios:**
- Initializer loads in development environment without raising
- Initializer loads in test environment with dummy keys
- `RubyLLM` module is available and responds to `chat` and `context`

---

### U2: Create unified AIBackend using RubyLLM

**Files:**
- `app/services/ai_backend.rb` — rewrite to use RubyLLM
- `app/services/ai_backend/utilities.rb` — keep or adapt `deep_streaming_merge`, `deep_json_parse`
- `app/services/ai_backend/open_ai.rb` — delete
- `app/services/ai_backend/open_ai/tools.rb` — delete
- `app/services/ai_backend/anthropic.rb` — delete
- `app/services/ai_backend/anthropic/tools.rb` — delete
- `app/services/ai_backend/gemini.rb` — delete
- `app/models/api_service.rb` — update `ai_backend` method
- `app/services/ai_backend/tools.rb` — adapt for RubyLLM

**Description:**
Rewrite the `AIBackend` class to use `RubyLLM.chat` as the single LLM interface. The class preserves the same public interface used by `GetNextAIMessageJob` and `AutotitleConversationJob`:

- `AIBackend.new(user, assistant, conversation, message)` — constructor builds a RubyLLM context with the user's API key and creates a `RubyLLM.chat` instance configured with the assistant's model
- `stream_next_conversation_message(&chunk_handler)` — uses `chat.ask` with a streaming block, yields text chunks, returns tool calls if present
- `get_oneoff_message(instructions, messages, params = {})` — non-streaming one-shot call
- `self.test_language_model(language_model, api_name)` — connectivity test
- `self.test_api_service(api_service, url, token)` — connectivity test
- `self.get_tool_messages_by_calling(tool_calls)` — execute tools (unchanged logic)

The constructor determines the RubyLLM provider from `APIService#driver`:
- `openai` → `provider: :openai` (also covers Groq via `openai_api_base`)
- `anthropic` → `provider: :anthropic`
- `gemini` → `provider: :gemini`

For custom URLs (Groq, user's own server), set the provider-specific `*_api_base` in the context. Use `assume_model_exists: true` since HostedGPT's model names may not be in RubyLLM's registry.

The `APIService#ai_backend` method should return the unified `AIBackend` class for all drivers. The `driver` enum is still used to determine the RubyLLM provider.

**Test file:** `test/services/ai_backend_test.rb` — comprehensive tests for the unified backend

**Test scenarios:**
- Initializing with an OpenAI driver service creates a working RubyLLM chat instance
- Initializing with an Anthropic driver service creates a working RubyLLM chat instance
- Initializing with a Gemini driver service creates a working RubyLLM chat instance
- Initializing with a Groq (openai driver, custom URL) service creates a working chat instance with custom api_base
- `stream_next_conversation_message` streams text chunks via the block
- `stream_next_conversation_message` returns tool calls when the model requests them
- `get_oneoff_message` returns a text response
- `get_oneoff_message` with JSON response format returns structured data
- `test_language_model` returns content on success
- `test_language_model` returns error message on failure
- `test_api_service` with blank token returns "Error: API key (token) is blank"
- `get_tool_messages_by_calling` properly executes tools (existing test should still pass)
- `get_tool_messages_by_calling` gracefully handles a failure within a function call
- `get_tool_messages_by_calling` gracefully handles calling an invalid function

---

### U3: Adapt message formatting for RubyLLM

**Files:**
- `app/services/ai_backend.rb` — implement `preceding_conversation_messages` using RubyLLM's message API

**Description:**
Replace the three provider-specific `preceding_conversation_messages` methods with a single unified method that builds conversation history using RubyLLM's `chat.add_message(role:, content:)` API. RubyLLM handles provider-specific encoding internally.

Key formatting concerns to preserve:
1. **Text messages:** `chat.add_message(role: :user, content: text)` / `chat.add_message(role: :assistant, content: text)`
2. **Image attachments:** For messages with images, use RubyLLM's file attachment support. The existing code extracts base64 data for Anthropic and image_url for OpenAI — RubyLLM handles this. Use `RubyLLM::Content` with attachments or `Content::Raw` blocks for the appropriate format.
3. **PDF documents:** The existing code extracts text from PDFs and includes it as text in the message. This logic can be preserved as-is (it's application-level text extraction, not provider-specific) — just add the extracted text as regular content.
4. **Tool call messages (assistant):** Messages where the assistant called a tool need `tool_calls` in the message. Use RubyLLM's `add_message` with the appropriate tool call structure.
5. **Tool result messages:** Tool results with `role: :tool` / `tool_call_id`. RubyLLM's message API supports tool role messages.
6. **Sanitization:** The existing OpenAI backend sanitizes `message_to_user` and `json_of_generated_image` from tool response content. This sanitization should be preserved.

The `full_instructions` method (system prompt + memories + current time/date) is preserved as-is and passed via `chat.with_instructions`.

**Test scenarios (in `test/services/ai_backend_test.rb`):**
- `preceding_conversation_messages` constructs proper text messages for a simple conversation
- `preceding_conversation_messages` only considers messages on the intended conversation version
- `preceding_conversation_messages` includes correct names for user and assistant
- `preceding_conversation_messages` includes image attachments for messages with documents
- `preceding_conversation_messages` includes PDF text extraction for PDF documents
- `preceding_conversation_messages` includes tool call details for assistant messages with tool_calls
- `preceding_conversation_messages` includes tool result messages for tool role messages
- `preceding_conversation_messages` handles PDF extraction errors gracefully (existing tests)

---

### U4: Migrate tool calling to RubyLLM

**Files:**
- `app/services/ai_backend.rb` — tool registration and tool-call interception
- `app/services/ai_backend/tools.rb` — adapt tool format conversion
- `app/services/toolbox.rb` — may need minor adaptation to expose tools in RubyLLM format

**Description:**
Register tools with RubyLLM so the model knows what tools are available and returns structured tool calls. Convert `Toolbox.tools` output (OpenAI function-calling format: `{type: "function", function: {name:, description:, parameters: {...}}}`) to RubyLLM's tool format. RubyLLM accepts manual JSON Schema for tools, which is compatible with the existing format.

For tool-call interception (see D3): when the model requests a tool call, intercept it from the streaming response (`chunk.tool_calls`) and return it to the caller instead of letting RubyLLM execute it automatically. The exact interception mechanism needs validation against RubyLLM's internals:
- Option A: Register tools that raise a special `ToolCallIntercepted` exception in their `execute` method, which halts RubyLLM's automatic execution and surfaces the tool call
- Option B: Use `before_tool_call` callback to capture the tool call and raise to halt execution
- Option C: Parse tool calls from stream chunks and don't register tools for execution (only for schema definition)

The `format_parallel_tool_calls` methods (provider-specific) are no longer needed since RubyLLM normalizes tool call format. The tool calls returned to `GetNextAIMessageJob` should be in the existing internal format (OpenAI-compatible) so `call_tools_before_wrapping_up` and `Toolbox.call` work unchanged.

The `AIBackend::Tools` module's `get_tool_messages_by_calling` class method is preserved — it dispatches tool calls via `Toolbox.call` and returns tool messages. This logic is provider-agnostic and unchanged.

**Test file:** `test/services/ai_backend/tools_test.rb` — update tool tests

**Test scenarios:**
- Tools are passed to RubyLLM when `language_model.supports_tools?` is true
- Tools are not passed when `language_model.supports_tools?` is false
- `stream_next_conversation_message` returns tool calls when the model requests them
- Tool calls returned are in the internal OpenAI-compatible format (id, function.name, function.arguments)
- Parallel tool calls are handled (multiple tool calls in one response)
- `get_tool_messages_by_calling` properly executes tools (existing test)
- `get_tool_messages_by_calling` gracefully handles a failure within a function call (existing test)
- `get_tool_messages_by_calling` gracefully handles calling an invalid function (existing test)

---

### U5: Migrate image generation to RubyLLM.paint

**Files:**
- `app/services/toolbox/image.rb` — replace `OpenAI::Client` with `RubyLLM.paint`
- `test/services/toolbox/image_test.rb` — update tests

**Description:**
Replace the `generate_with_openai_client` method in `Toolbox::Image` with `RubyLLM.paint`. The current code creates an `OpenAI::Client` and calls `client.images.generate`. Replace with:

```ruby
image = RubyLLM.paint(image_generation_prompt_s, model: "gpt-image-1")
```

RubyLLM's `paint` returns an image object with base64 data. Extract the base64 and return the same hash structure (`prompt_given`, `json_of_generated_image`, `note_to_assistant`, `message_to_user`).

The `openai_client` method that finds the user's OpenAI API service is replaced with a RubyLLM context that has the OpenAI key configured. The image tool should create a `RubyLLM.context` with the user's OpenAI key and call `paint` within it.

**Test scenarios:**
- `generate_an_image` calls RubyLLM.paint with expected params and returns payload
- `generate_an_image` works with Anthropic backend (uses RubyLLM context with OpenAI key)
- `generate_an_image` raises helpful error when OpenAI key is not configured

---

### U6: Update error handling in GetNextAIMessageJob

**Files:**
- `app/jobs/get_next_ai_message_job.rb` — update rescue clauses

**Description:**
Replace provider-specific error classes (`OpenAI::ConfigurationError`, `Anthropic::ConfigurationError`, `Gemini::Errors::ConfigurationError`) with RubyLLM's unified error hierarchy:

- `RubyLLM::ConfigurationError` → replaces all three `*::ConfigurationError` classes (maps to "invalid API key" messages)
- `RubyLLM::UnauthorizedError` → 401, invalid API key
- `RubyLLM::PaymentRequiredError` → 402, billing issue (replaces `Faraday::TooManyRequestsError` for billing errors)
- `RubyLLM::RateLimitError` → 429, rate limit
- `RubyLLM::ServerError` / `RubyLLM::ServiceUnavailableError` → 500/503, server issues
- `RubyLLM::BadRequestError` → 400, invalid request

The existing error messages (set_openai_error, set_anthropic_error, set_groq_error, set_generic_error) are preserved — they're keyed by `APIService#name`, not by exception class. The rescue clause changes from matching specific provider error classes to matching `RubyLLM::ConfigurationError` (which replaces all provider config errors).

The `set_billing_error` method maps provider names to billing URLs — this is preserved, but the trigger changes from `Faraday::TooManyRequestsError` to `RubyLLM::RateLimitError` or `RubyLLM::PaymentRequiredError`.

Remove the `class ::Gemini::Errors::ConfigurationError` monkey-patch at the top of the file.

**Test file:** `test/jobs/get_next_ai_message_job_test.rb` (and provider-specific job tests)

**Test scenarios:**
- When API key is blank, a nice error message is displayed (per provider name)
- When API response is blank/empty, a nice error message is displayed
- When rate-limited, a billing error message with the correct URL is displayed
- When a connection error occurs, a connection error message is displayed
- When an unexpected error occurs after 3 retries, an unexpected error message is displayed
- Response cancellation still works (ResponseCancelled exception)

---

### U7: Update AutotitleConversationJob

**Files:**
- `app/jobs/autotitle_conversation_job.rb`

**Description:**
Simplify the `generate_title_for` method. The existing code has provider-specific branches:
```ruby
if ai_backend.class == AIBackend::OpenAI || ai_backend.class == AIBackend::Anthropic
  # JSON mode
elsif ai_backend.class == AIBackend::Gemini
  # Gemini JSON mode
else
  # regex extraction
end
```

With the unified backend, this becomes a single path. Use RubyLLM's `with_params(response_format: { type: "json_object" })` for OpenAI-compatible models, or `with_schema` for structured output where supported. For models that don't support JSON mode, fall back to regex extraction.

The provider detection now uses `APIService#driver` instead of `ai_backend.class`. The Anthropic-specific system message addition (for JSON compliance) can be kept as a driver-specific branch or simplified.

**Test file:** `test/jobs/autotitle_conversation_job_test.rb`

**Test scenarios:**
- Generates a title from conversation messages (existing test)
- Works with OpenAI driver (JSON mode)
- Works with Anthropic driver (JSON mode with system message emphasis)
- Works with Gemini driver (JSON mode)
- Returns "ConversationNotReady" when no messages exist (existing test)
- Returns early when API key is blank (existing test)

---

### U8: Update test infrastructure

**Files:**
- `test/support/test_client/open_ai.rb` — replace or delete
- `test/support/test_client/anthropic.rb` — replace or delete
- `test/support/test_client/gemini.rb` — replace or delete
- `test/services/ai_backend/open_ai_test.rb` — merge into unified test
- `test/services/ai_backend/anthropic_test.rb` — merge into unified test
- `test/services/ai_backend/gemini_test.rb` — merge into unified test
- `test/services/ai_backend/anthropic/tools_test.rb` — merge into unified test
- `test/services/ai_backend/open_ai/tools_test.rb` — merge into unified test
- `test/jobs/get_next_ai_message_job_openai_test.rb` — update stubs
- `test/jobs/get_next_ai_message_job_anthropic_test.rb` — update stubs
- `test/jobs/get_next_ai_message_job_gemini_test.rb` — update stubs
- `test/models/api_service_test.rb` — update ai_backend assertions

**Description:**
Replace the three `TestClient::*` classes with a unified test stub mechanism for RubyLLM. The existing test clients mock the provider-specific client classes (`OpenAI::Client`, `Anthropic::Client`, `Gemini`). With RubyLLM, the mock target changes to `RubyLLM.chat` or `RubyLLM::Chat` instances.

Approach: Create a `test/support/ruby_llm_test_helper.rb` that stubs `RubyLLM.chat` to return a mock chat object. The mock chat object:
- Responds to `with_instructions`, `with_model`, `with_tools`, `with_params`, `add_message`
- Responds to `ask` — yields chunks with `content` and `tool_calls`, returns a final message
- Class-level stubs for `text` (the response text) and `function` (tool call function name) match the existing pattern

The existing test client pattern (stub `TestClient::OpenAI.text = "Hello"`) maps to stubbing the mock chat's response text. The test helper should provide the same stubbing interface so existing tests need minimal changes.

For `api_service_test.rb`, the `assert_equal AIBackend::OpenAI, ...` assertions change to `assert_equal AIBackend, ...` since there's one unified class.

**Test scenarios:**
- All existing test scenarios pass with the new mock infrastructure
- Mock chat yields streaming chunks in order
- Mock chat returns tool calls when configured
- Mock chat supports response_format / JSON mode

---

### U9: Remove old gems and clean up

**Files:**
- `Gemfile` — remove `ruby-openai`, `ruby-anthropic`, `gemini-ai`, `tiktoken_ruby`
- `Gemfile.lock` — regenerate
- `test/support/test_client/` — delete directory if empty
- `app/services/ai_backend/open_ai/` — delete directory
- `app/services/ai_backend/anthropic/` — delete directory
- `app/views/settings/api_services/_form.html.erb` — update Gemini credentials link (remove `gemini-ai` GitHub link)

**Description:**
Remove the four gems from the Gemfile and regenerate the lock file. Delete the now-empty provider-specific directories. Update any remaining references to the old gems in views or documentation.

The `tiktoken_ruby` gem is listed in the Gemfile but has no application code references — it was likely used for token counting in an earlier version. RubyLLM handles token counting via the response object, so this gem is no longer needed.

**Verification:**
- `bundle install` succeeds without the removed gems
- `bin/rails test` passes with the new gemset
- No `require "openai"`, `require "anthropic"`, or `require "gemini"` statements remain
- `grep -r "OpenAI::Client\|Anthropic::Client\|Gemini.new\|tiktoken" app/ lib/` returns no results

---

## Risks

1. **RubyLLM tool-call interception (D3):** The exact mechanism for intercepting tool calls without letting RubyLLM execute them needs validation. If RubyLLM doesn't easily support this, we may need to register dummy tools that raise, or parse tool calls from raw stream chunks. This is the highest-risk item.

2. **RubyLLM model registry vs custom models:** HostedGPT uses many model names (e.g., `gpt-4-1106-preview`, `claude-3-haiku-20240307`) that may not all be in RubyLLM's registry. Using `assume_model_exists: true` bypasses registry validation but also bypasses capability detection. We need to pass capabilities (supports_tools, supports_images) from our own `LanguageModel` records, not rely on RubyLLM's registry.

3. **Multi-modal message format:** The existing code has careful per-provider handling of images (base64 for Anthropic, URL for OpenAI, inline_data for Gemini). RubyLLM's `with:` parameter handles file paths and URLs, but the existing code works with Active Storage attachments (not file paths). We need to verify that RubyLLM can accept base64 data or io streams from Active Storage, or use `Content::Raw` blocks for custom payloads.

4. **Groq as OpenAI-compatible:** Groq uses the `openai` driver with a custom URL. RubyLLM supports OpenAI-compatible endpoints via `openai_api_base`. Need to verify that Groq's tool-calling format works through RubyLLM's OpenAI provider.

5. **Streaming behavior differences:** RubyLLM normalizes streaming into `Chunk` objects with `content` and `tool_calls`. The existing code expects raw intermediate response hashes. The streaming handler needs to be rewritten to work with RubyLLM's Chunk API.

## Existing Patterns to Follow

- `app/services/ai_backend.rb` — the base class pattern (constructor, public methods, private helpers)
- `app/jobs/get_next_ai_message_job.rb` — the job orchestration pattern (rescue clauses, error messages, tool execution)
- `test/support/test_client/` — the test client pattern (class-level stubs for `text`, `function`)
- `.github/copilot-instructions.md` — the "Adding a New AI Provider" guideline (steps 1-7)
- `config/initializers/` — the initializer pattern for gems (see `omniauth.rb`)
