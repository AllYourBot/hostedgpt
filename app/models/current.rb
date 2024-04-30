class Current < ActiveSupport::CurrentAttributes
  attribute :person
  attribute :user

  def user
    super&.tap do |user|
      user.preferences ||= {}
      user.preferences[:dark_mode] ||= 'system' if user.preferences[:dark_mode].nil?
    end
  end
end
