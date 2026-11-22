# frozen_string_literal: true

# Steps for user registration, mirroring test/system/users_test.rb.

Given("I am on the login page") do
  visit login_path
end

When("I follow the first {string} link") do |text|
  click_on text, match: :first
end

Then("I see {string} and {string} but not {string}") do |first, second, absent|
  assert_text first
  assert_text second
  refute_text absent
end

When("I fill the registration email and password") do
  fill_in "Email", with: "email@email.com"
  fill_in "Password", with: "secret"
end

When("I refill the registration email and password") do
  fill_in "Email", with: "changed@email.com"
  fill_in "Password", with: "secret" # this triggers a second focus event
end

Then("the full name field is revealed") do
  assert_visible "#person_personable_attributes_name"
end

Then("the full name field stays revealed") do
  assert_visible "#person_personable_attributes_name"
end

When("I sign up as {string} named {string}") do |email, name|
  @signup_email = email
  click_on "Sign up", match: :first
  fill_in "Email", with: email
  fill_in "Password", with: "secret"
  fill_in "Name", with: name
  click_on "Sign Up"

  # The system test sleeps 0.3s before the database assertions; wait for the
  # account instead.
  assert_true "waiting for the new user to be created" do
    signup_user&.name == name
  end
end

Then("I am on the new user's first assistant's new message page") do
  assert_current_path new_assistant_message_path(signup_user.assistants.ordered.first)
end

Then("the user {string} exists named {string} with a password credential") do |_email, name|
  user = signup_user
  assert_equal name, user.name
  assert_equal 1, user.credentials.count
  assert user.password_credential.password_digest.present?
end

def signup_user
  Person.find_by(email: @signup_email)&.user
end
