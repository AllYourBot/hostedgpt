require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get login_path
    assert_response :success
  end

  test "should create session" do
    post login_path, params: {
      email: people(:keith_registered).email,
      password: "secret"
    }
    assert_redirected_to root_url # we are not actually checking that a valid session was created?
  end

  test "should ignore case of email and create a session" do
    post login_path, params: {
      email: people(:keith_registered).email.capitalize,
      password: "secret"
    }
    assert_redirected_to root_url
  end

  test "it should redirect back with invalid password" do
    email = people(:keith_registered).email
    password = "wrong"

    post login_path, params: {email: email, password: password}
    assert_response :unprocessable_entity
    assert_match(/Invalid email or password/, flash.alert)
  end

  test "it should redirect back with invalid email" do
    email = "wrong"
    password = "secret"

    post login_path, params: {email: email, password: password}
    assert_response :unprocessable_entity
    assert_match(/Invalid email or password/, flash.alert)
  end

  test "it should strip whitespace around an email addresss" do
    email = people(:keith_registered).email
    email += " "
    password = "secret"

    post login_path, params: {email: email, password: password}
    assert_redirected_to root_url
  end

  test "it should redirect them to a conversation after login" do
    person = people(:keith_registered)
    post login_path, params: {email: person.email, password: "secret"}
    assert_redirected_to root_url
  end
end
