module Settings
  module APIServicesHelper
    def official?(model)
      openai?(model) || anthropic?(model) || groq?(model) || openrouter?(model) || gemini?(model) || brave?(model)
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

    def openrouter?(api_service)
      api_service.url == APIService::URL_OPENROUTER
    end

    def gemini?(api_service)
      api_service.url == APIService::URL_GEMINI
    end

    def brave?(api_service)
      api_service.url == APIService::URL_BRAVE
    end
  end
end
