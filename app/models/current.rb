class Current < ActiveSupport::CurrentAttributes
  attribute :person
  attribute :user
  attribute :client

  attribute :message # Maybe this should not be here, but get_next_ai_message_job calls tools and tools need this context

  def self.initialize_with(client: nil)
    self.client = client

    if client&.authenticated?
      self.person = client.person
      self.user = client.person&.user
    end

    self.user
  end

  def self.reset
    self.person = self.user = self.client = nil
  end
end
