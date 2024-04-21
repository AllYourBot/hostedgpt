module Message::Cancellable
  extend ActiveSupport::Concern

  included do
    after_save :save_cancelled_id_to_redis, if: :saved_change_to_cancelled_at?
  end

  private

  def save_cancelled_id_to_redis
    redis.set("message-cancelled-id", id)
  end

  def redis
    RedisConnection.client
  end
end
