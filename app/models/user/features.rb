class User::Features
  # OpenRouter rides the openai driver, so it needs its own name here. Groq
  # rides it too but stays out until RubyLLM support is verified.
  def self.derived_backend_names
    APIService.drivers.keys
      .select { |driver| APIService.new(driver: driver).ai_backend }
      .map { |driver| :"#{driver}_ai_backend" } + [:openrouter_ai_backend]
  end

  def self.valid_names
    derived_backend_names + [:use_ruby_llm]
  end

  def self.ruby_llm_available?(backend)
    defined?(AIBackend::RubyLLM) &&
      AIBackend::RubyLLM.respond_to?(:supports_driver?) &&
      AIBackend::RubyLLM.supports_driver?(backend)
  end

  def initialize(user)
    @user = user
  end

  def [](name)
    key = guard_name!(name)
    feature_preferences[key]
  end

  def []=(name, value)
    key = guard_name!(name)
    @user.update!(preferences: @user.preferences.deep_merge(feature: { key => value }))
  end

  private

  def feature_preferences
    sub_hash = @user.preferences[:feature] || @user.preferences["feature"] || {}
    sub_hash.transform_keys(&:to_sym)
  end

  def guard_name!(name)
    key = name.to_s.chomp("=").to_sym
    unless self.class.valid_names.include?(key)
      raise KeyError, "You attempted to reference '#{key}' but only AI-backend choices (<backend>_ai_backend) and use_ruby_llm are accessible here. Did you typo a feature name?"
    end

    key
  end
end
