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

  test "ai_backend works as a delegated attribute" do
    assert_equal AIBackend::OpenAI, language_models(:gpt_best).ai_backend
  end

  test "provider_name for Anthropic models" do
    assert_equal "claude-3-sonnet-20240229", language_models(:claude_3_sonnet_20240229).provider_name
    assert_equal "claude-3-opus-20240229", language_models(:claude_3_opus_20240229).provider_name
  end

  test "provider_name for OpenAI models" do
    assert_equal "gpt-3.5-turbo-0125", language_models(:gpt_3_5_turbo_0125).provider_name
    assert_equal "gpt-4o", language_models(:gpt_4o).provider_name
  end

  test "provider_name for best models" do
    assert_equal "gpt-4o-2024-08-06", language_models(:gpt_best).provider_name
    assert_equal "claude-3-5-sonnet-20240620", language_models(:claude_best).provider_name
  end

  test "provider_name for non-best models" do
    assert_equal "gpt-4o", language_models(:gpt_4o).provider_name
    assert_equal "claude-3-opus-20240229", language_models(:claude_3_opus_20240229).provider_name
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

  test "for_user scope" do
    list = LanguageModel.for_user(users(:keith)).all.pluck(:api_name)
    assert list.include?("camel")
    assert list.include?("gpt-best")
    refute list.include?("alpaca")

    list = LanguageModel.for_user(users(:taylor)).all.pluck(:api_name)
    refute list.include?("camel")
    assert list.include?("alpaca:medium")
  end

  test "export_to_file json" do
    path = Rails.root.join("tmp/models.json")
    LanguageModel.export_to_file(path:)
    assert File.exist?(path)
    json = JSON.load_file(path)
    assert_equal json.first.keys, %w[api_name name supports_images supports_tools input_token_cost_cents output_token_cost_cents]
  end

  test "export_to_file yaml" do
    path = Rails.root.join("tmp/models.yaml")
    LanguageModel.export_to_file(path:)
    assert File.exist?(path)
    yaml = YAML.load_file(path)
    assert_equal yaml.first.keys, %w[api_name name supports_images supports_tools input_token_cost_cents output_token_cost_cents]
  end

  private

  def create_params
    {
      api_name: "demo name",
      name: "good one",
      supports_images: true,
      api_service: api_services(:rob_other_service),
      user: users(:rob)
    }
  end
end
