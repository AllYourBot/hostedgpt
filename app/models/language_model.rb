# We don't care about large or not
class LanguageModel < ApplicationRecord
   def readonly?() = !new_record?
   def before_destroy() = raise ActiveRecord::ReadOnlyRecord

   PROVIDER_ID_MAP = {'gpt-best': 'gpt-4-turbo',
     'claude-best': 'claude-3-opus-20240229'}             
   def provider_id
     PROVIDER_ID_MAP[self.name.to_sym] || self.name unless self.name =~ /^best/
   end
end
