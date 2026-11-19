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

def sign_in_with(email, password)
  visit login_path
  fill_in "email", with: email
  fill_in "password", with: password
  click_on I18n.t("app.auth.login")
end
