class AIBackend::Policy::CheaperInference < AIBackend::Policy::Base
  def self.display_name
    "Cheaper Inference"
  end

  def self.key_error_message
    "(You need to enter a valid API key for Cheaper Inference to use its models. Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find Cheaper Inference Key instructions.)"
  end

  def self.billing_url
    "https://cheaperinference.com/"
  end
end
