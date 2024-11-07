module ConfigHelpers

  def teardown
    super

    unless @original_setting_values.nil?
      unstub_config_values
    end
  end

  private

  # stub_config_* methods are used to stub Rails.application.config values
  # e.g. stub_config_app_url("http://example.com") do block contents end
  # or
  # e.g. stub_config_app_url("http://example.com")
  def method_missing(method_name, *arguments, &block)
    if method_name.to_s.start_with?("stub_config_")
      setting_name = method_name.to_s.gsub("stub_config_", "").to_sym
      stub_config_value(setting_name, *arguments, &block)
    else
      super
    end
  end

  def stub_config_value(setting_name, value, &block)
    if block_given?
      Rails.application.config.stub(setting_name, value) do
        yield
      end
    else
      @original_setting_values ||= {}
      @original_setting_values[setting_name] = Rails.application.config.send(setting_name)

      Rails.application.config.send("#{setting_name}=", value)
      Rails.application.reloader.reload!
    end
  end

  def unstub_config_values
    @original_setting_values.each do |setting_name, value|
      Rails.application.config.send("#{setting_name}=", value)
    end
    Rails.application.reloader.reload!
    @original_setting_values = nil
  end
end
