module Personable
  extend ActiveSupport::Concern

  included do
    has_one :person, as: :personable, touch: true
  end

  delegate :email, to: :person
  delegate :clients, to: :person
end
