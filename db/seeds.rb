require "active_record/fixtures"

if Rails.env.development?
  order_to_load_fixtures = %w[people users tombstones assistants conversations runs messages steps]

  order_to_load_fixtures.each do |fixture_name|
    ActiveRecord::FixtureSet.create_fixtures("test/fixtures", fixture_name)
  end
end