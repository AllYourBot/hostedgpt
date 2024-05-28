module FeatureHelpers

  private

  def stub_features(hash, &block)
    Feature.features_hash = nil
    Feature.stub :raw_features, -> { Rails.application.config.options.features.merge(hash) } do
      yield
    end
    Feature.features_hash = nil
  end
end
