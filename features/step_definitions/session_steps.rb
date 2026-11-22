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

def sign_in_as(user, password = "secret")
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
  fill_in "email", with: user.email
  fill_in "password", with: password
  click_on I18n.t("app.auth.login")
end

def sign_in_with(email, password)
  visit login_path
  fill_in "email", with: email
  fill_in "password", with: password
  click_on I18n.t("app.auth.login")
end
