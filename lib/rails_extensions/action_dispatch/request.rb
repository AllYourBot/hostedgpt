module ActionDispatch
  class Request
    KNOWN_OPERATING_SYSTEMS = ["Windows", "Macintosh", "Linux", "Android", "iPhone"].freeze
    KNOWN_BROWSERS = ["Chrome", "Safari", "Firefox", "Edge", "Opera"].freeze

    def operating_system
      get_item_in_str(user_agent, KNOWN_OPERATING_SYSTEMS) || "unknown operating system"
    end

    def browser
      get_item_in_str(user_agent, KNOWN_BROWSERS) || "unknown browser"
    end

    private

    def get_item_in_str(str, items)
      items.each do |item|
        if str.include?(item)
          return item
        end
      end
    end
  end
end
