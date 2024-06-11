class Current < ActiveSupport::CurrentAttributes
  attribute :person
  attribute :user
  attribute :client

  def self.initialize_with(client: nil)
    self.client = client

    if client&.is_a?(Client) && client&.authenticated?
      self.person = client.person
      self.user = client.person&.user
    end

    self.user
  end

  def self.reset
    self.person = self.user = self.client = nil
  end
end
