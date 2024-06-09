require "active_record/fixtures"

unless Rails.env.test?
  puts "loading fixtures"

  order_to_load_fixtures = %w[language_models]

  ActiveRecord::Base.transaction do
    ActiveRecord::FixtureSet.create_fixtures(Rails.root.join('test', 'fixtures'), order_to_load_fixtures)
  end
end
