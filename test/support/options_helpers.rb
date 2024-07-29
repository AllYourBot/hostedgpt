module OptionsHelpers

  private

  def stub_settings_and_features(&block)
    stub_settings(@settings || {}) do
      stub_features(@features || {}) do
        yield
      end
    end
  end

  def stub_features(hash, &block)
    Feature.features_hash = nil
    Feature.stub :raw_features, -> { Rails.application.config.options.features.merge(hash) } do
      yield
    end
    Feature.features_hash = nil
  end

  def stub_settings(hash, &block)
    Setting.stub :settings, -> { Rails.application.config.options.settings.merge(hash) } do
      yield
    end
  end
end
