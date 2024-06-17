class Current < ActiveSupport::CurrentAttributes
  attribute :person
  attribute :user
  attribtue :message
  attribute :client

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
