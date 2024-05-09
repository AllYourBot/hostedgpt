require "active_record/fixtures"

if Rails.env.development?

  puts "loading fixtures"
  order_to_load_fixtures = %w[people users tombstones assistants conversations runs messages steps]

  ActiveRecord::Base.transaction do
    ActiveRecord::Base.connection.disable_referential_integrity do
      ActiveRecord::FixtureSet.create_fixtures(Rails.root.join('test', 'fixtures'), order_to_load_fixtures)
    end
  end
end