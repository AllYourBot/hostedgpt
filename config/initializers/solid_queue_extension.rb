module CustomProcess
  def heartbeat
    # only silence if explicitly set to not log (default to logging)
    # true or not set (or anything else) means log, false means silence
    silence_heartbeat = ENV["SOLID_QUEUE_LOG_HEARTBEAT_ON"] == "false"

    if silence_heartbeat && ActiveRecord::Base.logger
      ActiveRecord::Base.logger.silence { super }
    else
      super
    end
  end
end

Rails.application.config.after_initialize do
  SolidQueue::Process.send(:prepend, CustomProcess)
end
