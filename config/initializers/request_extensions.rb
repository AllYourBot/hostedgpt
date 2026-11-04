ActionDispatch::Request.class_eval do
  KNOWN_OPERATING_SYSTEMS = ["Windows", "Macintosh", "Linux", "Android", "iPhone"].freeze
  KNOWN_BROWSERS = ["Chrome", "Safari", "Firefox", "Edge", "Opera"].freeze

  def operating_system = KNOWN_OPERATING_SYSTEMS.detect { user_agent.include?(it) } || "unknown operating system"

  def browser = KNOWN_BROWSERS.detect { user_agent.include?(it) } || "unknown browser"
end
