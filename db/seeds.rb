require "active_record/fixtures"

if Rails.env.production?
  module ActiveRecord
    module ConnectionAdapters
      class PostgreSQLAdapter
        def disable_referential_integrity
          yield
        end
      end
    end
  end
end

unless Rails.env.test?
  puts "loading fixtures"

  order_to_load_fixtures = %w[language_models]

  ActiveRecord::Base.transaction do
    ActiveRecord::FixtureSet.create_fixtures(Rails.root.join("test", "fixtures"), order_to_load_fixtures)
  end
end
