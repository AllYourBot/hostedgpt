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

  test "has effective_api_name when not -best" do
    assert_equal "gpt-4o", language_models(:gpt_4o).effective_api_name
    assert_equal "gpt-4o-2024-05-13", language_models(:gpt_4o_2024_05_13).effective_api_name
  end

  test "effective_api_name needs current user when api_name ends in best" do
    exc = assert_raises do 
      language_models(:gpt_best).effective_api_name
    end
    assert_equal "Could not resolve best model for gpt-best from API service OpenAI", exc.to_s
  end

  test "has effective_api_name when api_name ends in best" do
    Current.stub :user, users(:keith) do
      assert_equal "gpt-4o", language_models(:gpt_best).effective_api_name
    end
  end

  test "ai_backend works as a delegated attribute" do
    assert_equal AIBackend::OpenAI, language_models(:gpt_best).ai_backend
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
