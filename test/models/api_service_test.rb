require "test_helper"

class APIServiceTest < ActiveSupport::TestCase
  test "has user" do
    assert_equal users(:keith), api_services(:keith_service).user
  end

  test "name present validated" do
    record = APIService.new(name: '')
    refute record.valid?
    assert_equal ["can't be blank"], record.errors[:name]
  end

  test "driver list validated" do
    record = APIService.new(driver: 'oink')
    refute record.valid?
    assert_equal ["is not included in the list"], record.errors[:driver]
  end

  test "URL present validated" do
    record = APIService.new(url: ' ')
    refute record.valid?
    assert_equal ["can't be blank"], record.errors[:url]

    record = APIService.new(url: '')
    refute record.valid?
    assert_equal ["can't be blank"], record.errors[:url]
  end

  test "validates URL format validated" do
    record = APIService.new(url: 'oh')
    refute record.valid?
    assert_equal ["is invalid"], record.errors[:url]
  end

  test "encrypts token" do
    api_service = api_services(:keith_service)
    old_cipher_text = api_service.ciphertext_for(:token)
    api_service.update!(token: "new secret")
    assert api_service.reload
    refute_equal old_cipher_text, api_service.ciphertext_for(:token)
    assert_equal "new secret", api_service.token
  end

  test "ai_backend" do
    assert_equal AIBackend::Anthropic, api_services(:rob_service).ai_backend
    assert_equal AIBackend::OpenAI, api_services(:keith_service).ai_backend
  end

  test "soft_deletion" do
    api_service = api_services(:keith_service)
    assert_nil api_service.reload.deleted_at
    assert_no_difference "APIService.count" do
      api_service.destroy!
    end
    refute_nil api_service.reload.deleted_at
  end

  test "destroy with assistant" do
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

  test "cannot create record without user" do
    record = APIService.new(api_service_params.except(:user))
    assert_no_difference "APIService.count" do
      refute record.save
      assert_equal ["User must exist"],  record.errors.full_messages
    end
  end

  test "can create record" do
    record = APIService.new(api_service_params)
    assert_difference "APIService.count" do
      assert record.save, record.errors.full_messages.inspect
    end
  end

  private

  def api_service_params
    {user: users(:taylor),
      name: "ABC Serv",
      driver: "Anthropic",
      url: "http://abcdef.com/models",
      token: "access-token"}
  end
end
