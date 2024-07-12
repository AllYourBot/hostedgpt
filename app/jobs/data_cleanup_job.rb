class DataCleanupJob < ApplicationJob

  queue_as :default

  def perform
    user_ids = Message.
      joins(:conversation => :user).
      group('users.id').
      having('MAX(messages.created_at) < ?', 3.days.ago).
      pluck('users.id')

    User.where(id: user_ids).destroy_all
  end
end
