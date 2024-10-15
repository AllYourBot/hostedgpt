
# Rails.application.configure do

#   module SolidQueue

#     class CustomSolidQueueProcess
#       def heartbeat
#         puts "heartbeat"
#         Rails.logger.info "in heartbeat for process #{id}"

#         # stuff_to_do = lambda {
#         #   puts "stuff_to_do"
#         #   ActiveRecord::Base.logger.info "Updating heartbeat for process #{id}"
#         #   # Clear any previous changes before locking, for example, in case a previous heartbeat
#         #   # failed because of a DB issue (with SQLite depending on configuration, a BusyException
#         #   # is not rare) and we still have the unpersisted value
#         #   restore_attributes
#         #   with_lock { touch(:last_heartbeat_at) }
#         # }

#         # only silence if explicitly set to not log
#         silence_heartbeat = ENV["SOLID_QUEUE_LOG_HEARTBEAT_ON"] == "false"

#         # ActiveRecord::Base.logger.silence stuff_to_do

#         if silence_heartbeat && ActiveRecord::Base.logger
#           Rails.logger.info "Silencing heartbeat for process #{id}"
#           puts "foo"
#           # ActiveRecord::Base.logger.silence { touch(:last_heartbeat_at) }
#           ActiveRecord::Base.logger.silence super
#         else
#           Rails.logger.info "Updating heartbeat for process #{id}"
#           # touch(:last_heartbeat_at)
#           super
#           puts "bar"
#         end
#       rescue e
#         Rails.logger.error "Error updating heartbeat for process #{id}"
#         puts "e"
#         puts e
#         raise e
#       end
#     end

#     class Process < Record
#       prepend CustomSolidQueueProcess
#     end

#   end

# end
