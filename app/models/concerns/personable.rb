module Personable
  extend ActiveSupport::Concern

  included do
    has_one :person, as: :personable, touch: true

    delegate :email, to: :person
    delegate :clients, to: :person
  end
end
