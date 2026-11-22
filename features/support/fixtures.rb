# frozen_string_literal: true

# Loads the same fixtures the minitest suite uses so cucumber scenarios share
# one source of test data. Rows inserted here survive to the scenario: they land
# inside the per-scenario transaction (non-javascript) or are committed for the
# browser to see and truncated after (javascript).
#
# The fixture machinery comes from ActiveRecord::TestFixtures, which the
# cucumber World inherits through ActionDispatch::IntegrationTest: configuring
# the class-level fixture_paths + fixture sets makes `users(:keith)`-style
# accessors work in steps (via TestFixtures#method_missing), exactly like the
# minitest suite's `fixtures :all`.
module FixturesSupport
  # Named differently from TestFixtures#load_fixtures so it does not shadow it.
  def load_scenario_fixtures
    # Without these resets, create_fixtures finds the sets cached from the
    # previous scenario and inserts nothing.
    ActiveRecord::FixtureSet.reset_cache
    # setup_fixtures lazily initializes this class variable before using it; we
    # bypass setup_fixtures (cucumber's database strategy owns transactions),
    # so initialize it here.
    ActiveRecord::TestFixtures.class_variable_defined?(:@@already_loaded_fixtures) ||
      ActiveRecord::TestFixtures.send(:class_variable_set, :@@already_loaded_fixtures, {})
    invalidate_already_loaded_fixtures
    @fixture_cache = {}
    @loaded_fixtures = load_fixtures(ActiveRecord::Base)
  end
end

World(FixturesSupport)

Cucumber::Rails::World.fixture_paths = [Rails.root.join("test/fixtures")]
Cucumber::Rails::World.fixtures(:all)

Before("not @no-fixtures") do
  load_scenario_fixtures
end
