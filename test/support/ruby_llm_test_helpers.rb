module RubyLLMTestHelpers
  def stub_rubyllm_client
    AIBackend::RubyLLM.stub(:client, TestClient::RubyLLM) do
      AIBackend::RubyLLM.stub(:chat_class, TestClient::RubyLLM::Chat) do
        yield
      end
    end
  end
end
