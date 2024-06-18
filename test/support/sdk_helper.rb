module SDKHelpers

  private

  def stub_get_response(hash, &block)
    SDK::Verb.stub_any_instance :get, response_for(hash) do
      yield
    end
  end

  def stub_post_response(hash, &block)
    SDK::Verb.stub_any_instance :get, response_for(hash) do
      yield
    end
  end

  def response_for(hash)
    OpenData.new(
      status: hash[:status] || 200,
      body: hash.except(:status).to_json
    )
  end
end
