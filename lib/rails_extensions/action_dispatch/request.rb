module ActionDispatch
  class Request
    KNOWN_OPERATING_SYSTEMS = ["Windows", "Macintosh", "Linux", "Android", "iPhone"].freeze
    KNOWN_BROWSERS = ["Chrome", "Safari", "Firefox", "Edge", "Opera"].freeze

    def operating_system
      KNOWN_OPERATING_SYSTEMS.detect { |os| user_agent.include?(os) } || "unknown operating system"
    end

    def browser
      KNOWN_BROWSERS.detect { |browser| user_agent.include?(browser) } || "unknown browser"
    end
  end
end
