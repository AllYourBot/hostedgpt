class AIBackend::Policy::Gemini < AIBackend::Policy::Base
  def self.key_error_message
    "(There is a configuration error with the Gemini API Service. Maybe you have an invalid API key? " +
      "Click your Profile in the bottom left and then Settings and then **API Services**. You will find Gemini there.)"
  end

  def self.billing_url
    "https://aistudio.google.com/app/apikey"
  end
end
