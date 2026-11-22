# frozen_string_literal: true

# NOTE: Chrome 158 teardown compatibility shim (added 2026-11-22).
#
# ISSUE
# Capybara 3.40 clears cookies/storage during every browser reset through a CDP
# call: `Storage.clearDataForOrigin` with `origin: "*"` (see
# capybara-3.40.0/lib/capybara/selenium/driver_specializations/chrome_driver.rb,
# ChromeDriver#reset!). Chrome 158's chromedriver began validating that origin
# parameter and rejects the wildcard with
# `Selenium::WebDriver::Error::InvalidArgumentError: invalid argument: * is not
# a valid URL`, so every browser-driving test fails at teardown — both minitest
# system tests (ApplicationSystemTestCase after_teardown) and cucumber
# @javascript scenarios (Capybara.reset_sessions! in the After hook).
#
# SOLUTIONS CONSIDERED
# - Upgrade capybara: a newer capybara may stop sending the wildcard origin or
#   handle chromedriver's validation (check the capybara changelog for
#   chromedriver / Storage.clearDataForOrigin fixes). Declined for now — this
#   branch is a framework evaluation and should not bump dependencies mid-trial.
# - Pin Chrome (CI `browser-actions/setup-chrome` chrome-version, and downgrade
#   local Chrome to 157): declined — local Chrome auto-updates and every stable
#   release re-breaks CI.
# - THIS SHIM: rescue exactly the failing CDP command and clear cookies through
#   the param-less `Network.clearBrowserCookies` CDP command instead (also CDP,
#   but it carries no origin argument for chromedriver to reject, and it clears
#   every origin, matching the wildcard semantics of the call it replaces).
#   Chosen because it adds no dependencies, works on any Chrome, and is a
#   strict no-op wherever the CDP call still succeeds (Chrome <= 157): the
#   rescue never fires, behavior is unchanged.
#
# The app stores nothing in localStorage/sessionStorage (verified 2026-11-22 by
# searching app/javascript), so clearing cookies covers everything the CDP path
# cleared. Note: the W3C fallback `browser.manage.delete_all_cookies` is scoped
# to the active document's origin, so it cannot replace the wildcard clear from
# reset!'s about:blank — do not substitute it here.
#
# REMOVE THIS FILE (both copies) when capybara fixes the CDP call or
# chromedriver accepts the wildcard origin again:
#   test/support/chrome_reset_compat.rb
#   features/support/chrome_reset_compat.rb
module ChromeResetCompat
  def execute_cdp(cmd, params = {})
    super
  rescue Selenium::WebDriver::Error::InvalidArgumentError
    raise unless cmd == "Storage.clearDataForOrigin"

    execute_cdp("Network.clearBrowserCookies")
  end
end

require "capybara/selenium/driver" # eager-loads the Chrome specialization
Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeResetCompat)
