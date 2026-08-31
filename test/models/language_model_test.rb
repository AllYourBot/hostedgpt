require "test_helper"

class LanguageModelTest < ActiveSupport::TestCase
  test "has associated assistant" do
    assert_instance_of Assistant, language_models(:gpt_4o).assistants.first
  end

  test "has an associated user" do
    assert_instance_of User, language_models(:gpt_4o).user
  end

  test "has an associated api_service" do
    assert_instance_of APIService, language_models(:gpt_best).api_service
  end

  test "has tools_supported" do
    assert language_models(:gpt_4o).supports_tools?
    refute language_models(:guanaco).supports_tools?
  end

  test "tools support combines the model attribute with the backend's policy" do
    # attribute true + backend allowed -> tools sent (today's default-named behavior)
    assert language_models(:gpt_4o).supports_tools?

    # attribute false -> denied regardless of the backend's policy
    model = language_models(:gpt_4o)
    model.supports_tools = false
    refute model.supports_tools?
  end

  test "a model on a service without a backend denies tools" do
    brave_service = api_services(:keith_brave_service)
    model = language_models(:gpt_4o)
    model.update!(api_service: brave_service, supports_tools: true)

    refute model.supports_tools?
  end

  test "ai_backend works as a delegated attribute" do
    assert_equal AIBackend::OpenAI, language_models(:gpt_best).ai_backend
  end

  test "logo_filename" do
    assert_equal "openai_logo.svg", language_models(:gpt_4o).logo_filename
    assert_equal "claude_logo.svg", language_models(:claude_best).logo_filename
    assert_equal "google_gemini_logo.svg", language_models(:"gemini-1.5-pro-002").logo_filename
    assert_nil language_models(:guanaco).logo_filename # api_service has no recognized logo and name isn't a llama model

    assert_equal "meta_ai_logo.svg", LanguageModel.new(api_name: "llama-3.3-70b-versatile").logo_filename
  end

  test "validates api_name" do
    record = LanguageModel.new(api_name: "")
    refute record.valid?
    assert_equal ["can't be blank"], record.errors[:api_name]
  end

  test "validates name" do
    record = LanguageModel.new(name: "")
    refute record.valid?
    assert_equal ["can't be blank"], record.errors[:name]
  end

  test "cannot create without user" do
    record = LanguageModel.new(create_params.except(:user))
    refute record.valid?
    assert_equal ["must exist"], record.errors[:user]
  end

  test "cannot create without api_service" do
    record = LanguageModel.new(create_params.except(:api_service))
    refute record.valid?
    assert_equal ["must exist"], record.errors[:api_service]
  end

  test "can create" do
    max_position = users(:rob).language_models.maximum(:position)
    record = LanguageModel.create!(create_params)
    assert_equal users(:rob), record.user
    assert_equal max_position+1, record.position
  end

  test "create with an existing position preserves that" do
    record = LanguageModel.create!(create_params.merge(position: 1000))
    assert_equal 1000, record.position
  end

  test "soft delete also soft deletes assistants" do
    assert_difference "users(:rob).assistants.reload.count", -language_models(:rob_gpt).assistants.count do
      assert_difference "users(:rob).language_models.reload.count", -1 do
        assert_changes "assistants(:rob_gpt4).reload.deleted_at", from: nil do
          assert_changes "language_models(:rob_gpt).deleted_at", from: nil do
            language_models(:rob_gpt).deleted!
          end
        end
      end
    end
  end

  test "models.yml has 25 OpenRouter entries that import successfully" do
    storage = YAML.load_file(Rails.root.join("models.yml"))
    openrouter_models = storage["models"].select { |m| m["api_service_name"] == "OpenRouter" }
    assert_equal 25, openrouter_models.count

    user = users(:keith)
    LanguageModel.import_from_file(users: [user])
    by_api_name = user.language_models.joins(:api_service).where(api_services: { name: "OpenRouter" }).index_by(&:api_name)

    openrouter_models.each do |model|
      lm = by_api_name[model["api_name"]]
      assert lm, "Expected #{model['api_name']} to be imported"
      assert_equal model["supports_tools"], lm.supports_tools
      assert_equal model["supports_images"], lm.supports_images
    end
  end

  test "for_user scope" do
    list = LanguageModel.for_user(users(:keith)).all.pluck(:api_name)
    assert list.include?("camel")
    assert list.include?("gpt-best")
    refute list.include?("alpaca")

    list = LanguageModel.for_user(users(:taylor)).all.pluck(:api_name)
    refute list.include?("camel")
    assert list.include?("alpaca:medium")
  end

  private

  def create_params
    {
      api_name: "demo name",
      name: "good one",
      supports_images: true,
      supports_pdf: false,
      api_service: api_services(:rob_other_service),
      user: users(:rob)
    }
  end
end
