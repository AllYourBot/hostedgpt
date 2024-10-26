module Settings
  module APIServicesHelper
    def official?(model)
      openai?(model) || anthropic?(model) || groq?(model) || gemini?(model)
    end

    def openai?(api_service)
      api_service.url == APIService::URL_OPEN_AI
    end

    def anthropic?(api_service)
      api_service.url == APIService::URL_ANTHROPIC
    end

    def groq?(api_service)
      api_service.url == APIService::URL_GROQ
    end

    def gemini?(api_service)
      api_service.url == APIService::URL_GEMINI
    end
  end
end
