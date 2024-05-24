module FeatureHelpers

  private

  def stub_features(hash, &block)
    Feature.features_hash = nil
    Feature.stub :features, hash do
      yield
    end
    Feature.features_hash = nil
  end

  def stub_raw_features(hash, &block)
    Feature.features_hash = nil
    Feature.stub :raw_features, hash do
      yield
    end
    Feature.features_hash = nil
  end
end
