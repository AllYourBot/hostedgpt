class RedisConnection
  def self.client
    @@redis ||= Rails.env.test? ? MockRedis.new : Redis.new
  end
end
