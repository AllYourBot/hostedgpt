module SDKHelpers

  private

  def stub_response(verb, method, hash, &block)
    stubbed_method = "mocked_response_#{verb}_#{method}"

    SDK::Verb.define_singleton_method(stubbed_method) { {} }
    SDK::Verb.stub stubbed_method, response_for(hash) do
      yield
    end
  end

  def stub_get_response(method, hash, &block)
    stub_response(:get, method, hash, &block)
  end

  def stub_post_response(method, hash, &block)
    stub_response(:post, method, hash, &block)
  end

  def response_for(hash)
    response = hash.except(:status)
    if response.keys.length == 1 && response[:response]
      response = response[:response]
    end

    OpenData.new(
      status: hash[:status] || 200,
      body: response.to_json,
    )
  end
end
