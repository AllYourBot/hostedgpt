require "application_system_test_case"

class AssistantsTest < ApplicationSystemTestCase
  setup do
    login_as users(:keith)
    visit root_path
  end

  test "the hamburger reveals the nav when the window is too narrow to show it" do
    narrow_the_window do
      assert_true("The transition controller should have connected") do
        page.evaluate_script("!!(window.Stimulus && window.Stimulus.getControllerForElementAndIdentifier(document.body, 'transition'))")
      end

      assert_no_selector "nav #nav-scrollable", visible: true

      click_element "#narrow-header button"

      assert_selector "nav #nav-scrollable", visible: true
    end
  end

  private

  def narrow_the_window
    page.current_window.resize_to(500, 800)
    yield
  ensure
    page.current_window.resize_to(1400, 800) # the window outlives the test, so hand it back the way we found it
  end
end
