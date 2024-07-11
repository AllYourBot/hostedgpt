class DataCleanupJob < ApplicationJob

  queue_as :default

  def perform
    threshold = 90.days.ago

    user_ids = Message.
      select('users.id as user_id, MAX(messages.created_at) as max_messages_created_at').
      joins(:conversation => :user).
      group('users.id').
      to_a.select do |message|
        message.max_messages_created_at < threshold
      end.map(&:user_id)

    User.where(id: user_ids).each(&:destroy)
  end
end
