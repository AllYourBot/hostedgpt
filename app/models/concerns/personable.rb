module Personable
  extend ActiveSupport::Concern

  included do
    has_one :person, as: :personable, touch: true
  end
end
