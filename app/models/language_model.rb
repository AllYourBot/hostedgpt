# We don't care about large or not
class LanguageModel < ApplicationRecord
   def readonly?() = !new_record?
   def before_destroy() = raise ActiveRecord::ReadOnlyRecord
end
