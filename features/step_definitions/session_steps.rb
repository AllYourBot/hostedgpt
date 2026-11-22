Given("a user with a password") do
  @user = Person.find_by(email: "keith@hostedgpt.com")&.personable
  assert_not_nil @user, "expected the keith fixtures to provide a registered user"
  assert @user.password_credential&.authenticate("secret"), "expected keith's password credential to accept 'secret'"
end

When("I sign in") do
  sign_in_with(@user.email, "secret")
end

When("I sign in with the wrong password") do
  sign_in_with(@user.email, "wrong-password")
end

Then("I reach my app") do
  assert_current_path root_path
end

Then("the sign in is refused") do
  assert_current_path login_path, ignore_query: true
  assert_text I18n.t("app.flashes.auth.invalid_login")
end

Given("I am signed in") do
  sign_in_as users(:keith)
end

def sign_in_as(user_or_person, password = "secret")
  # Mirrors ApplicationSystemTestCase#login_as: accept a Person or a User.
  user = user_or_person.is_a?(Person) ? user_or_person.user : user_or_person

  # Headless Chrome ignores mouse input for the whole of the first browser
  # session in a process, so the first sign-in resets the session once to prime
  # the pointer (mirrors ApplicationSystemTestCase#login_as).
  prime_pointer do
    log_in_with user, password
  end

  if Feature.assistants_page?
    assert_current_path root_path
    visit new_assistant_message_path(user.assistants.ordered.first)
  else
    assert_current_path new_assistant_message_path(user.assistants.ordered.first)
  end
end

# Mirrors ApplicationSystemTestCase#log_in: one navigation to the login page
# (via the logout redirect), fill, submit. Navigating to login_path a second
# time races the redirected page load and can drop the filled value.
def log_in_with(user, password)
  visit logout_path
  assert_current_path login_path
  fill_login_form(user.email, password)
  submit_login_form
end

When("I sign in from the root page") do
  # Paths (not *_url helpers) here: the World's url generation has no request
  # context, so *_url resolves to the default test host instead of the
  # Capybara server.
  visit root_path
  assert_current_path login_path, ignore_query: true
  fill_login_form users(:keith).email, "secret"
  submit_login_form
end

Then("I am on my first assistant's new message page") do
  assistant = users(:keith).assistants.ordered.first
  assert_current_path new_assistant_message_path(assistant)
end

Then("the email field is focused") do
  assert_active "#email"
end

When("I log out") do
  visit logout_path
  assert_current_path login_path
end

When("I log in with my email and password") do
  fill_login_form users(:keith).email, "secret"
  submit_login_form
end

When("I log in with my email and the wrong password") do
  fill_login_form users(:keith).email, "wrong"
  submit_login_form
end

Then("I see {string}") do |text|
  assert_text text
end

Then("I do not see {string}") do |text|
  assert_no_text text
end

Then("my email stays pre-filled") do
  assert_equal users(:keith).email, find("#email").value
end

Then("the password field is focused") do
  assert_active "#password"
end

Then("I stay on the login page") do
  assert_current_path login_path, ignore_query: true
end

def fill_login_form(email, password)
  fill_in "Email address", with: email
  fill_in "Password", with: password
end

def submit_login_form
  # The login form submits via Turbo; its redirect target renders in
  # turbo-stream format and Turbo can leave the DOM on the login page (the
  # server-side session is created either way). A native submit gives the
  # deterministic full-page POST + redirect the system tests rely on. The
  # rack-test driver (non-JS scenarios) submits natively anyway and cannot
  # execute scripts, so it just clicks.
  if page.driver.is_a?(Capybara::RackTest::Driver)
    click_on I18n.t("app.auth.login")
  else
    page.execute_script("document.querySelector(\"form[action='/login']\").submit()")
    # A successful login lands on the app (the assistants nav appears); a
    # refused login lands back on the login page with the error flash. Wait
    # for either so the step is outcome-agnostic. The document is briefly
    # mid-navigation during the poll, where DOM queries raise — treat those
    # as "not yet".
    assert_true "waiting for the login form submission to land" do
      begin
        page.has_selector?("#assistants", wait: 0) ||
          page.has_text?(I18n.t("app.flashes.auth.invalid_login"), wait: 0)
      rescue Capybara::ElementNotFound, Capybara::NotSupportedByDriverError, Selenium::WebDriver::Error::WebDriverError
        false
      end
    end
  end
end

def sign_in_with(email, password)
  visit login_path
  fill_in "email", with: email
  fill_in "password", with: password
  click_on I18n.t("app.auth.login")
end
