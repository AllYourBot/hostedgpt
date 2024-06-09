module Message::Cancellable
  extend ActiveSupport::Concern

  included do
    has_one :cancelled_by, class_name: "User", inverse_of: :last_cancelled_message, dependent: :nullify

    after_save :set_cancelled_by, if: :saved_change_to_cancelled_at?
  end

  private

  def set_cancelled_by
    Current.user&.update!(last_cancelled_message: self)
  end
end
