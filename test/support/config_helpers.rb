module ConfigHelpers

  def teardown
    super

    unless @original_values.nil?
      unstub_custom_config_values
    end
  end

  private

  def stub_custom_config_value(key, value, &block)
    @original_values ||= {}

    if block_given?
      Rails.application.config.x.stub(key, value) do
        yield
      end
    else
      @original_values[key] = Rails.application.config.x.send(key)

      Rails.application.config.x.send("#{key}=", value)
      Rails.application.reloader.reload!
    end
  end

  def unstub_custom_config_values
    @original_values.each do |key, value|
      Rails.application.config.x.send("#{key}=", value)
    end
    Rails.application.reloader.reload!
    @original_values = {}
  end
end
