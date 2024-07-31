module OptionsHelpers

  def teardown
    super

    unless @original_features.nil?
      unstub_features
    end

    unless @original_settings.nil?
      unstub_settings
    end
  end

  private

  def stub_features(hash, &block)
    Feature.features_hash = nil
    if block_given?
      Feature.stub :raw_features, -> { Rails.application.config.options.features.merge(hash) } do
        yield
      end
    else
      @original_features = Feature.method(:raw_features)
      Feature.define_singleton_method(:raw_features) { Rails.application.config.options.features.merge(hash) }
      Rails.application.reload_routes!
    end
    Feature.features_hash = nil
  end

  def stub_settings(hash, &block)
    if block_given?
      Setting.stub :settings, -> { Rails.application.config.options.settings.merge(hash) } do
        yield
      end
    else
      @original_settings = Setting.method(:settings)
      Setting.define_singleton_method(:settings) { Rails.application.config.options.settings.merge(hash) }
      Rails.application.reload_routes!
    end
  end

  def unstub_features
    Feature.singleton_class.send(:remove_method, :raw_features)
    Feature.define_singleton_method(:raw_features, @original_features)
    Feature.features_hash = nil
    Rails.application.reload_routes!
    @original_features = nil
  end

  def unstub_settings
    Setting.singleton_class.send(:remove_method, :settings)
    Setting.define_singleton_method(:settings, @original_settings)
    Rails.application.reload_routes!
    @original_settings = nil
  end
end
