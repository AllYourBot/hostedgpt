require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user" do
    post users_url, params: {person: {personable_type: "User", email: "azbshiri@gmail.com", personable_attributes: user_attr}}
    assert_response :redirect
    follow_redirect!
    follow_redirect! # intentionally two redirects
    assert_response :success
  end

  test "it should redirect back when the email address is already in use" do
    email = people(:keith_registered).email
    post users_url, params: {person: {personable_type: "User", email: email, personable_attributes: user_attr}}
    assert_response :unprocessable_entity
    assert_match "Email has already been taken", response.body
  end

  test "it should show an error message when the password is blank" do
    email = people(:keith_registered).email
    post users_url, params: {person: {personable_type: "User", email: email, personable_attributes: user_attr.merge({ password: "" })}}
    assert_response :unprocessable_entity
    assert_match "Password can&#39;t be blank", response.body
  end

  test "it should show an error message when the email is blank" do
    post users_url, params: {person: {personable_type: "User", email: "", personable_attributes: user_attr}}
    assert_response :unprocessable_entity
    assert_match "Email can&#39;t be blank", response.body
  end

  test "after create, an account should be bootstrapped and taken to a conversation" do
    email = "fake_email#{rand(1000)}@example.com"
    post users_url, params: {person: {personable_type: "User", email: email, personable_attributes: user_attr}}

    user = Person.find_by(email: email).user
    assert_equal user_attr.except(:password), user.slice(:first_name, :last_name).symbolize_keys
    assert_equal 4, user.assistants.count, "This new user did not get the expected number of assistants"

    assistant = user.assistants.ordered.first

    follow_redirect!
    assert_redirected_to new_assistant_message_path(assistant)
  end

  private

  def user_attr
    { password: "secret", first_name: "John", last_name: "Doe" }
  end
end
