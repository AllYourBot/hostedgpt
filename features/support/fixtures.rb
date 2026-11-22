# Loads the same fixtures the minitest suite uses so cucumber scenarios share
# one source of test data. Rows inserted here survive to the scenario: they land
# inside the per-scenario transaction (non-javascript) or are committed for the
# browser to see and truncated after (javascript).
module FixturesSupport
  # Include nested fixture directories (active_storage/*) so image/document
  # scenarios can attach real fixture blobs, like the minitest suite does.
  FIXTURE_TABLES = Dir[Rails.root.join("test/fixtures/**/*.yml")].sort.map do |path|
    prefix = "#{Rails.root.join('test/fixtures')}/"
    path.delete_prefix(prefix).delete_suffix(".yml")
  end.freeze

  def load_fixtures
    # Without this, create_fixtures finds the sets cached from the previous
    # scenario and inserts nothing (ActiveRecord re-inserts only when uncached).
    ActiveRecord::FixtureSet.reset_cache
    ActiveRecord::FixtureSet.create_fixtures(Rails.root.join("test/fixtures"), FIXTURE_TABLES)
  end
end

World(FixturesSupport)

Before("not @no-fixtures") do
  load_fixtures
end
