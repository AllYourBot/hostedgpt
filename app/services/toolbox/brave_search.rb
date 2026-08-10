class Toolbox::BraveSearch < Toolbox

  describe :brave_search, <<~S
    Search Brave for the indicated query.
    Use this to answer questions about current events, look up information, or find answers to questions.
    Try to use this sparingly; prefer to use the user's memories and the tools you have available to answer questions.
    When you do use this, try to use exact queries for which you expect to get a definitive answer.
    When you respond to the user, try to include an answer to the question rather than just a link.
  S
  def brave_search(query_s:)
    response = get(brave_service.url + "web/search").param(q: query_s)

    results = Array(response.try(:web).try(:results)).map do |result|
      "#{result.title} (#{result.url}): #{result.description}"
    end.join("\n")

    {
      message_to_user: "Web query: #{query_s}",
      query_results: results.presence || "No results found."
    }
  end

  private

  def brave_service
    @brave_service ||= find_brave_service
  end

  def find_brave_service
    service = Current.user.api_services.find_by(driver: :brave)
    raise "Brave API key not found. Web search requires a Brave Search API key. Please configure your Brave API key in Settings > API Services." if service.nil? || service.effective_token.blank?
    service
  end

  def header
    {
      "X-Subscription-Token": brave_service.effective_token,
      "Accept": "application/json",
      "Accept-Encoding": "gzip",
    }
  end
end
