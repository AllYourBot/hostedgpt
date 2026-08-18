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
    stub_features(assistants_page: true) do
      post users_url, params: { person: { personable_type: "User", email: "azbshiri@gmail.com", personable_attributes: user_attr } }
      assert_response :redirect
      follow_redirect!
      assert_response :success
    end
  end

  test "should redirect back when the email address is already in use" do
    email = people(:keith_registered).email
    post users_url, params: { person: { personable_type: "User", email: email, personable_attributes: user_attr } }
    assert_response :unprocessable_content
    assert_match "Email has already been taken", response.body
  end

  test "should show an error message when the password is blank" do
    email = people(:keith_registered).email
    modified_user_attr = user_attr
    modified_user_attr[:credentials_attributes]["0"][:password] = ""
    post users_url, params: { person: { personable_type: "User", email: email, personable_attributes: modified_user_attr } }
    assert_response :unprocessable_content
    assert_match "Password can&#39;t be blank", response.body
  end

  test "should show an error message when the email is blank" do
    post users_url, params: { person: { personable_type: "User", email: "", personable_attributes: user_attr } }
    assert_response :unprocessable_content
    assert_match "Email can&#39;t be blank", response.body
  end

  test "after create, an account should be bootstrapped and redirect to new conversation if assistants_page is disabled" do
    stub_features(assistants_page: false) do
      email = "fake_email#{rand(1000)}@example.com"
      post users_url, params: { person: { personable_type: "User", email: email, personable_attributes: user_attr } }

      user = Person.find_by(email: email).user
      assert_equal "John", user.first_name
      assert_equal "Doe", user.last_name
      assert_equal 6, user.assistants.count, "This new user did not get the expected number of assistants"

      assert_redirected_to root_path
      follow_redirect!
      assistant = user.assistants.ordered.first
      assert_redirected_to new_assistant_message_path(assistant)
    end
  end

  test "after create, an account should be bootstrapped and shown assistants if assistants_page is enabled" do
    stub_features(assistants_page: true) do
      email = "fake_email#{rand(1000)}@example.com"
      post users_url, params: { person: { personable_type: "User", email: email, personable_attributes: user_attr } }

      user = Person.find_by(email: email).user
      assert_equal "John", user.first_name
      assert_equal "Doe", user.last_name
      assert_equal 6, user.assistants.count, "This new user did not get the expected number of assistants"

      assert_redirected_to root_path
      follow_redirect!
      assert_response :success
      assert_select "h1", "Assistants"
    end
  end

  test "preferences merge preserves unrelated keys when setting nav_closed" do
    user = users(:keith)
    user.preferences = { dark_mode: "light", feature: { use_ruby_llm: true } }
    user.save!
    login_as user

    patch user_url(user), params: { user: { preferences: { nav_closed: true } } }
    assert_response :redirect
    user.reload

    assert user.preferences[:nav_closed]
    assert_equal "light", user.preferences[:dark_mode]
    assert_equal({ use_ruby_llm: true }, user.preferences[:feature])
  end

  test "updates nav_closed preference without touching other preferences" do
    user = users(:keith)
    user.update!(dark_mode: "dark", nav_closed: false)
    login_as user

    patch user_url(user), params: { user: { nav_closed: true } }
    assert_response :redirect
    user.reload

    assert_equal true, user.nav_closed
    assert_equal "dark", user.dark_mode, "sidebar toggle must not disturb dark_mode"
  end

  private

  def user_attr
    { name: "John Doe", credentials_attributes: { "0" => { type: "PasswordCredential", password: "secret" } } }
  end
end
