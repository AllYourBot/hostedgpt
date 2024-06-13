require "test_helper"

class LanguageModelTest < ActiveSupport::TestCase
  test "has associated assistant" do
    assert_instance_of Assistant, language_models(:gpt_4o).assistants.first
  end

  test "can have User" do
    assert_instance_of User, language_models(:guanaco).user
    assert_nil language_models(:gpt_best).user
  end

  test "can have API Service" do
    assert_instance_of APIService, language_models(:guanaco).api_service
    assert_nil language_models(:gpt_best).api_service
  end

  test "validates name" do
    record = LanguageModel.new(name: '')
    refute record.valid?
    assert_equal ["can't be blank"], record.errors[:name]
  end

  test "validates description" do
    record = LanguageModel.new(description: '')
    refute record.valid?
    assert_equal ["can't be blank"], record.errors[:description]
  end

  test "is readonly?" do
    assert language_models(:gpt_best).readonly?
    assert !language_models(:alpaca).readonly?
  end

  test "cannot create without user" do
    record = LanguageModel.new(name: "demo name", description: "good one", supports_images: false)
    assert record.valid?
    assert record.readonly?
    assert_no_difference 'LanguageModel.count' do
      assert_raises ActiveRecord::ReadOnlyRecord do
        refute record.save
      end
    end
  end

  test "can create" do
    record = LanguageModel.new(name: "demo name", description: "good one", supports_images: true, user: users(:rob))
    assert record.valid?
    assert_difference 'LanguageModel.count' do
      assert record.save
    end
    record.reload
    assert_equal users(:rob).id, record.user_id
    assert record.position > 0
  end

  test "supports_images?" do
    assert language_models(:gpt_best).supports_images?
    refute language_models(:gpt_3_5_turbo).supports_images?
  end

  test "provider_name for Anthropic models" do
    assert_equal "claude-3-sonnet-20240229", language_models(:claude_3_sonnet_20240229).provider_name
    assert_equal "claude-3-opus-20240229", language_models(:claude_3_opus_20240229).provider_name
  end

  test "provider_name for OpenAI models" do
    assert_equal "gpt-3.5-turbo-0125", language_models(:gpt_3_5_turbo_0125).provider_name
    assert_equal "gpt-4o", language_models(:gpt_4o).provider_name
  end

  test "ai_backend for best models" do
    assert_equal AIBackend::OpenAI, language_models(:gpt_best).ai_backend
    assert_equal AIBackend::Anthropic, language_models(:claude_best).ai_backend
  end

  test "ai_backend for user models" do
    assert_equal AIBackend::Anthropic, language_models(:alpaca).ai_backend
    assert_equal AIBackend::OpenAI, language_models(:guanaco).ai_backend
  end

  test "destroy is soft-delete" do
    language_model = language_models(:alpaca)
    assert_nil language_model.reload.deleted_at
    assert_difference "language_model.reload.assistants.count", -1 do
      assert_no_difference 'Assistant.count' do
        assert_no_difference 'LanguageModel.count' do
          assert language_model.destroy!
        end 
      end
    end
    assert_not_nil language_model.reload.deleted_at
  end

  test "can delete from db when deleting user" do
    language_model = language_models(:camel)
    assert_equal users(:keith), language_model.user
    assert_difference 'LanguageModel.count', -2 do
      assert users(:keith).destroy!
    end 
    assert_equal 0, LanguageModel.where(id: language_model.id).count
  end

  test "for_user scope" do
    list = LanguageModel.for_user(users(:keith)).all.pluck(:name)
    assert list.include?('camel')
    assert list.include?('gpt-best')
    refute list.include?('alpaca')

    list = LanguageModel.for_user(users(:taylor)).all.pluck(:name)
    refute list.include?('camel')
    assert list.include?('gpt-best')
    assert list.include?('alpaca:medium')
  end

  test "system_wide scope" do
    list = LanguageModel.system_wide.all.pluck(:name)
    assert list.include?('gpt-best')
    refute list.include?('camel')
    refute list.include?('alpaca:medium')
  end

  test "provider_name for best models" do
    assert_equal "gpt-4o-2024-05-13", language_models(:gpt_best).provider_name
    assert_equal "claude-3-opus-20240229", language_models(:claude_best).provider_name
  end

  test "provider_name for non-best models" do
    assert_equal "gpt-4o", language_models(:gpt_4o).provider_name
    assert_equal "claude-3-opus-20240229", language_models(:claude_3_opus_20240229).provider_name
  end
end
