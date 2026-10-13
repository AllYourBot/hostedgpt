require "test_helper"
require "rake"

Rails.application.load_tasks unless Rake::Task.task_defined?("models:refresh")

class ModelsRefreshTest < ActiveSupport::TestCase
  test "models:refresh accepts Groq catalog entries if RubyLLM adds them" do
    assert_equal APIService.chat_provider_identities, LanguageModel::RefreshFromRubyLLM::CANONICAL_PROVIDER_URLS.keys
    registry = RubyLLM::Models.new([
      registry_model("future-groq-model", "Groq registry model", "groq", input: %w[text])
    ])

    with_registry(registry) do
      assert_output(/Added 1 language models/, /No chat models found in the RubyLLM registry for: openai, anthropic, openrouter, gemini/) do
        invoke_refresh_task
      end
    end

    assert_equal "Groq registry model", users(:keith).language_models.find_by!(
      api_service: api_services(:keith_groq_service),
      api_name: "future-groq-model"
    ).name
    refute users(:keith).language_models_including_deleted.exists?(
      api_service: api_services(:keith_openai_service),
      api_name: "future-groq-model"
    )
  end

  test "models:refresh imports chat models for their matching provider services" do
    registry = RubyLLM::Models.new([
      registry_model("shared-refresh-model", "OpenAI registry model", "openai", input: %w[text image], capabilities: %w[function_calling]),
      registry_model("shared-refresh-model", "Anthropic registry model", "anthropic", input: %w[text pdf]),
      registry_model("shared-refresh-model", "Gemini registry model", "gemini", input: %w[text image], capabilities: %w[function_calling]),
      registry_model("shared-refresh-model", "OpenRouter registry model", "openrouter", input: %w[text])
    ])

    openai_model = users(:keith).language_models.create!(
      api_service: api_services(:keith_openai_service),
      api_name: "shared-refresh-model",
      name: "My OpenAI label",
      supports_images: false,
      supports_tools: false
    )
    assistant = assistants(:keith_gpt4)
    assistant.update!(language_model: openai_model)

    deleted_anthropic_model = users(:keith).language_models.create!(
      api_service: api_services(:keith_anthropic_service),
      api_name: "shared-refresh-model",
      name: "Previously removed Claude model",
      supports_images: false,
      supports_tools: false
    )
    deleted_anthropic_model.update!(deleted_at: Time.current)

    custom_model = users(:keith).language_models.create!(
      api_service: api_services(:keith_other_service),
      api_name: "shared-refresh-model",
      name: "Custom endpoint model",
      supports_images: false,
      supports_tools: false
    )

    with_registry(registry) do
      assert_output(/Added 4 language models/, /No chat models found in the RubyLLM registry for: groq/) do
        invoke_refresh_task
      end

      assert_no_difference "LanguageModel.count" do
        assert_output(/Added 0 language models/, /No chat models found in the RubyLLM registry for: groq/) do
          invoke_refresh_task
        end
      end
    end

    assert_equal "My OpenAI label", openai_model.reload.name
    assert_equal false, openai_model.supports_images
    assert_equal openai_model.id, assistant.reload.language_model_id
    assert_equal "Previously removed Claude model", deleted_anthropic_model.reload.name
    assert_equal deleted_anthropic_model.id, users(:keith).language_models_including_deleted
      .find_by!(api_service: api_services(:keith_anthropic_service), api_name: "shared-refresh-model").id
    assert_equal "Custom endpoint model", custom_model.reload.name
    assert_equal custom_model.id, users(:keith).language_models_including_deleted
      .find_by!(api_service: api_services(:keith_other_service), api_name: "shared-refresh-model").id

    expected_names = {
      "openai" => "My OpenAI label",
      "anthropic" => "Previously removed Claude model",
      "gemini" => "Gemini registry model",
      "openrouter" => "OpenRouter registry model"
    }
    expected_names.each do |identity, name|
      service = api_services("keith_#{identity}_service")
      model = users(:keith).language_models_including_deleted.find_by!(
        api_service: service,
        api_name: "shared-refresh-model"
      )
      assert_equal name, model.name, "Expected #{identity} service to keep its own registry entry"
    end

    openai_entry = users(:rob).language_models.find_by!(
      api_service: api_services(:rob_openai_service),
      api_name: "shared-refresh-model"
    )
    assert_equal "OpenAI registry model", openai_entry.name
    assert_equal true, openai_entry.supports_images
    assert_equal true, openai_entry.supports_tools

    anthropic_entry = users(:rob).language_models.find_by!(
      api_service: api_services(:rob_anthropic_service),
      api_name: "shared-refresh-model"
    )
    assert_equal "Anthropic registry model", anthropic_entry.name
    assert_equal true, anthropic_entry.supports_pdf

    gemini_entry = users(:keith).language_models.find_by!(
      api_service: api_services(:keith_gemini_service),
      api_name: "shared-refresh-model"
    )
    assert_equal true, gemini_entry.supports_images
    assert_equal true, gemini_entry.supports_tools
    assert_equal true, gemini_entry.supports_system_message

    openrouter_entry = users(:keith).language_models.find_by!(
      api_service: api_services(:keith_openrouter_service),
      api_name: "shared-refresh-model"
    )
    assert_equal false, openrouter_entry.supports_images
    assert_equal false, openrouter_entry.supports_tools
    assert_equal false, openrouter_entry.supports_pdf
    refute users(:keith).language_models_including_deleted.exists?(
      api_service: api_services(:keith_groq_service),
      api_name: "shared-refresh-model"
    ), "OpenAI catalog entries must not be copied to Groq"
    refute users(:keith).language_models_including_deleted.exists?(
      api_service: api_services(:keith_brave_service),
      api_name: "shared-refresh-model"
    ), "Providers without a RubyLLM catalog entry must be skipped"
    %i[rob_other_service taylor_anthropic_service taylor_openai_service].each do |service_name|
      service = api_services(service_name)
      refute service.user.language_models_including_deleted.exists?(
        api_service: service,
        api_name: "shared-refresh-model"
      ), "Custom endpoint services must not receive a canonical provider's catalog"
    end
  end

  test "models:refresh leaves existing and soft-deleted model records untouched" do
    registry = RubyLLM::Models.new([
      registry_model("same-id", "OpenAI entry", "openai", input: %w[text]),
      registry_model("same-id", "Anthropic entry", "anthropic", input: %w[text])
    ])
    existing = users(:keith).language_models.create!(
      api_service: api_services(:keith_openai_service),
      api_name: "same-id",
      name: "Custom display name",
      supports_images: true,
      supports_tools: false
    )
    assistant = assistants(:keith_gpt4)
    assistant.update!(language_model: existing)
    deleted = users(:keith).language_models.create!(
      api_service: api_services(:keith_anthropic_service),
      api_name: "same-id",
      name: "Deleted catalog entry",
      supports_images: false,
      supports_tools: false
    )
    deleted.update!(deleted_at: Time.current)

    with_registry(registry) do
      assert_output(
        /Added 2 language models/,
        /No chat models found in the RubyLLM registry for: groq, openrouter, gemini/
      ) { invoke_refresh_task }
    end

    assert_equal "Custom display name", existing.reload.name
    assert_equal true, existing.supports_images
    assert_equal existing.id, assistant.reload.language_model_id
    assert_equal deleted.id, deleted.reload.id
    assert_equal Time.current.to_date, deleted.deleted_at.to_date
  end

  test "models:refresh stops before writing when RubyLLM refresh fails" do
    registry = RubyLLM::Models.new([
      registry_model("unwritten-model", "Unwritten model", "openai", input: %w[text])
    ])

    with_registry(registry, refresh: -> { raise Faraday::ConnectionFailed, "registry unavailable" }) do
      assert_raises(Faraday::ConnectionFailed) { invoke_refresh_task }
    end

    refute users(:keith).language_models_including_deleted.exists?(api_name: "unwritten-model")
  end

  test "models:refresh leaves the database unchanged when the registry is empty" do
    registry = RubyLLM::Models.new([])

    with_registry(registry) do
      assert_no_difference "LanguageModel.count" do
        assert_output(/Added 0 language models/, /No chat models found in the RubyLLM registry for:/) do
          invoke_refresh_task
        end
      end
    end
  end

  private

  def registry_model(id, name, provider, input:, capabilities: [])
    RubyLLM::Model::Info.new(
      id:,
      name:,
      provider:,
      modalities: { input:, output: ["text"] },
      capabilities:
    )
  end

  def with_registry(registry, refresh: nil, &block)
    refresh ||= -> {}
    RubyLLM.stub :models, registry do
      registry.stub :refresh!, refresh, &block
    end
  end

  def invoke_refresh_task
    task = Rake::Task["models:refresh"]
    task.reenable
    task.invoke
  end
end
