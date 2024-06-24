module Settings
  module APIServicesHelper
    def official?(model)
      openai?(model) || anthropic?(model)
    end

    def openai?(api_service)
      api_service.url == APIService::URL_OPEN_AI
    end

    def anthropic?(api_service)
      api_service.url == APIService::URL_ANTHROPIC
    end
  end
end
