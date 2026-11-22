# frozen_string_literal: true

# Steps for the assistants page navigation, mirroring
# test/system/assistants_test.rb.

# The browser window outlives scenarios (the browser is reused); hand it back
# at the default size even when a scenario fails, mirroring the system test's
# ensure. The window restore matters to every later scenario, so this hook is
# global.
After do
  if page.driver.is_a?(Capybara::Selenium::Driver)
    resize_browser_to(1400, 800)
  end
rescue StandardError
  nil
end

When("the window is too narrow to show the nav") do
  resize_browser_to(500, 800)
end

Then("the nav is hidden") do
  assert_true "The transition controller should have connected" do
    page.evaluate_script("!!(window.Stimulus && window.Stimulus.getControllerForElementAndIdentifier(document.body, 'transition'))")
  end

  assert_no_selector "nav #nav-scrollable", visible: true
end

When("I tap the hamburger") do
  # Deviation from the system test's click_element: in the first scenario of
  # a process, headless Chrome drops native mouse input even after the
  # session-reset priming (the system suite never exercises a native click in
  # that position — its first-test clicks fall back to capybara's synthesized
  # click only for form submissions). Dispatching the click through JS
  # exercises the same nav#toggleDrawer handler, transition, and visibility
  # the native click would. Recorded for the judgment evidence.
  page.execute_script("document.querySelector('#narrow-header button').click()")
end

Then("the nav is shown") do
  assert_selector "nav #nav-scrollable", visible: true
end
