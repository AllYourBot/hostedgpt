require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get redirected if already logged in" do
    login_as users(:keith)
    get register_url
    assert_response :redirect
  end

  test "should get new when logged out" do
    get register_url
    assert_response :success
  end

  test "should hide the Sign Up link if the registration feature is disabled" do
    stub_features(registration: false) do
      get root_url
      follow_redirect!
      assert_response :success
      assert_no_match "Sign up", response.body, "Sign up should be hidden when the registration feature is disabled"
    end
  end

  test "should create user" do
    post users_url, params: { person: { personable_type: "User", email: "azbshiri@gmail.com", personable_attributes: user_attr } }
    assert_response :redirect
    follow_redirect!
    follow_redirect! # intentionally two redirects
    assert_response :success
  end

  test "should redirect back when the email address is already in use" do
    email = people(:keith_registered).email
    post users_url, params: { person: { personable_type: "User", email: email, personable_attributes: user_attr } }
    assert_response :unprocessable_entity
    assert_match "Email has already been taken", response.body
  end

  test "should show an error message when the password is blank" do
    email = people(:keith_registered).email
    modified_user_attr = user_attr
    modified_user_attr[:credentials_attributes]["0"][:password] = ""
    post users_url, params: { person: { personable_type: "User", email: email, personable_attributes: modified_user_attr } }
    assert_response :unprocessable_entity
    assert_match "Password can&#39;t be blank", response.body
  end

  test "should show an error message when the email is blank" do
    post users_url, params: { person: { personable_type: "User", email: "", personable_attributes: user_attr } }
    assert_response :unprocessable_entity
    assert_match "Email can&#39;t be blank", response.body
  end

  test "after create, an account should be bootstrapped and taken to a conversation" do
    email = "fake_email#{rand(1000)}@example.com"
    post users_url, params: { person: { personable_type: "User", email: email, personable_attributes: user_attr } }

    user = Person.find_by(email: email).user
    assert_equal "John", user.first_name
    assert_equal "Doe", user.last_name
    assert_equal 5, user.assistants.count, "This new user did not get the expected number of assistants"

    assistant = user.assistants.ordered.first

    follow_redirect!
    assert_redirected_to new_assistant_message_path(assistant)
  end

  test "updates user preferences" do
    user = users(:keith)
    login_as user

    assert_changes "user.preferences[:nav_closed]", to: true do
      assert_changes "user.preferences[:dark_mode]", to: "dark" do
        patch user_url(user), params: { user: { preferences: { nav_closed: true, dark_mode: "dark" } } }
        user.reload
      end
    end
    assert_response :redirect
  end

  private

  def user_attr
    { name: "John Doe", credentials_attributes: { "0" => { type: "PasswordCredential", password: "secret" } } }
  end
end
