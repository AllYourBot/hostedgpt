# frozen_string_literal: true

# Ported skips: minitest's `skip` maps to a scenario skipped through cucumber's
# own API — a tag alone skips nothing in cucumber, so wire the mechanism here.
Before("@skip") do
  skip_this_scenario
end

# Diagnostics parity: minitest system tests save screenshots to tmp/screenshots
# on failure; do the same for cucumber scenarios so CI artifacts cover both
# suites.
After do |scenario|
  next unless scenario.failed?

  name = scenario.name.parameterize
  path = Rails.root.join("tmp/screenshots", "cucumber_#{Time.now.strftime('%Y%m%d%H%M%S')}_#{name}.png")
  begin
    page.save_screenshot(path.to_s) # rubocop:disable Lint/Debugger -- writes a file for CI artifacts, does not open anything
    attach(path.read, "image/png") if respond_to?(:attach)
  rescue StandardError => e
    warn "cucumber screenshot failed: #{e.class} #{e.message}"
  end
end
