require "test_helper"

class AIBackendGroqTest < ActiveSupport::TestCase
  test "key_error_message returns the recorded Groq copy" do
    assert_equal "(You need to enter a valid API key for Groq to use Llama. Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find Groq Key instructions.)",
      AIBackend::Groq.key_error_message
  end

  test "billing_url returns the Groq keys console" do
    assert_equal "https://console.groq.com/keys", AIBackend::Groq.billing_url
  end

  test "tools policy denies Groq" do
    assert_not AIBackend::Groq.supports_tools?
  end

  test "tools policy allows by default on the base and flows to OpenAI through inheritance" do
    assert AIBackend.supports_tools?
    assert AIBackend::OpenAI.supports_tools?
  end
end
