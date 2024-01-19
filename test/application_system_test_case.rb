require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  fixtures :all

  def login_as(user, password = "secret")
    visit login_path
    fill_in "email", with: user.person.email
    fill_in "password", with: password
    click_on "Continue"
    assert_text "Successfully logged in."
  end
end
