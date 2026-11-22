# frozen_string_literal: true

# Feature/settings/config stubs for cucumber, ported from
# test/support/options_helpers.rb and test/support/config_helpers.rb. Only the
# persistent form is ported: minitest's block stubs cannot wrap "the rest of a
# step", so a step stubs the option, acts, and the After hook unstubs — with a
# config reload, mirroring the minitest teardown.
module StubHelpers
  def stub_features(hash)
    Feature.features_hash = nil
    @original_features = Feature.method(:raw_features)
    Feature.define_singleton_method(:raw_features) { Rails.application.config.options.features.merge(hash) }
    Rails.application.reloader.reload!
    Feature.features_hash = nil
  end

  def unstub_features
    return unless @original_features

    Feature.singleton_class.send(:remove_method, :raw_features)
    Feature.define_singleton_method(:raw_features, @original_features)
    Feature.features_hash = nil
    Rails.application.reloader.reload!
    @original_features = nil
  end

  def stub_settings(hash)
    @original_settings = Setting.method(:settings)
    Setting.define_singleton_method(:settings) { Rails.application.config.options.settings.merge(hash) }
    Rails.application.reloader.reload!
  end

  def unstub_settings
    return unless @original_settings

    Setting.singleton_class.send(:remove_method, :settings)
    Setting.define_singleton_method(:settings, @original_settings)
    Rails.application.reloader.reload!
    @original_settings = nil
  end

  def stub_custom_config_value(key, value)
    @original_values ||= {}
    @original_values[key] = Rails.application.config.x.send(key)

    Rails.application.config.x.send("#{key}=", value)
    Rails.application.reloader.reload!
  end

  def unstub_custom_config_values
    return if @original_values.blank?

    @original_values.each do |key, value|
      Rails.application.config.x.send("#{key}=", value)
    end
    Rails.application.reloader.reload!
    @original_values = {}
  end
end

World(StubHelpers)

After do
  unstub_features if @original_features
  unstub_settings if @original_settings
  unstub_custom_config_values if @original_values
end
