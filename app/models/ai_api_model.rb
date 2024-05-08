class AIAPIModel < ApplicationRecord
   def readonly?() = !new_record?
   def before_destroy() = raise ActiveRecord::ReadOnlyRecord
end
