module SDKHelpers

  private

  def stub_response(verb, method, status:, response: {}, &block)
    stubbed_method = "mocked_response_#{verb}_#{method}"

    SDK::Verb.define_singleton_method(stubbed_method) { {} }
    SDK::Verb.stub stubbed_method, response_for(status, response) do
      yield
    end
  end

  def stub_get_response(method, status:, response: {}, &block)
    stub_response(:get, method, status: status, response: response, &block)
  end

  def stub_post_response(method, status:, response: {}, &block)
    stub_response(:post, method, status: status, response: response, &block)
  end

  def stub_patch_response(method, status:, response: {}, &block)
    stub_response(:patch, method, status: status, response: response, &block)
  end

  def stub_delete_response(method, status:, response: {}, &block)
    stub_response(:delete, method, status: status, response: response, &block)
  end

  def response_for(status, hash)
    OpenData.new(
      status: status,
      body: hash.to_json,
    )
  end
end
