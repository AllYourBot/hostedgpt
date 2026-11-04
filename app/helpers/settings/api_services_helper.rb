module Settings
  module APIServicesHelper
    def official?(model)
      openai?(model) || anthropic?(model) || groq?(model) || openrouter?(model) || gemini?(model) || brave?(model)
    end

    def openai?(api_service) = api_service.url == APIService::URL_OPEN_AI

    def anthropic?(api_service) = api_service.url == APIService::URL_ANTHROPIC

    def groq?(api_service) = api_service.url == APIService::URL_GROQ

    def openrouter?(api_service) = api_service.url == APIService::URL_OPENROUTER

    def gemini?(api_service) = api_service.url == APIService::URL_GEMINI

    def brave?(api_service) = api_service.url == APIService::URL_BRAVE

    def instruction_step(key, link_text, url)
      tag.li t("app.settings.api_services.instructions.#{key}",
        link: link_to(link_text, url, class: "underline text-blue-600", target: "_blank"))
    end
  end
end
