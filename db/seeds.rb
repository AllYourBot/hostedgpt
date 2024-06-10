require "active_record/fixtures"

if Rails.env.production?
  module ActiveRecord
    class FixtureSet
      def self.check_all_foreign_keys_valid!(*args)
        puts "Skipping referential integrity check for foreign"
      end
    end
  end
end

unless Rails.env.test?
  puts "Loading fixtures"

  order_to_load_fixtures = %w[language_models]

  ActiveRecord::Base.transaction do
    ActiveRecord::FixtureSet.create_fixtures(Rails.root.join("test", "fixtures"), order_to_load_fixtures)
  end
end
