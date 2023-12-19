# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :user, :request_id, :user_agent, :ip_address, :session
end
