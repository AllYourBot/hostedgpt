class ConversationStarter
  def self.sample
    conversation_starters = [
      ["Suggest a healthy meal plan", "for a week for someone with a busy schedule"],
      ["Plan a solo travel itinerary", "for a weekend getaway in a mountainous region"],
      ["Compose a short biography of Matz", "focusing on his philosophy behind creating Ruby"],
      ["Help me pick", "an outfit that will look good on camera"],
      ["Create a personal webpage for me", "after asking me three questions"],
      ["Recommend activities", "for a team-building day with remote employees"],
      ["Write a SQL query", "that adds a \"status\" column to an \"orders\" table"],
      ["Explain the significance of quantum computing", "in addressing complex problems"],
      ["Create a weekly newsletter template", "for a gardening club"],
      ["Recommend traditional Bavarian dishes", "and where to find them in Munich"],
      ["Craft a clever invitation", "for an engineering book club"],
      ["Write a survival guide", "for making it through a day with no coffee"],
      ["Help me plan", "a roadtrip from Charleston to Key West"]
    ]

    conversation_starters.shuffle[0..3]
  end
end
