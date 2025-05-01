require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    visit root_url
  end

  test "should login as an existing user" do
    assert_active "#email"

    fill_in "Email address", with: @user.email
    fill_in "Password", with: "secret"
    click_text "Log In"

    sleep 0.1
    assert_current_path new_assistant_message_path(@user.assistants.ordered.first)
  end

  test "when password is wrong, it shows an error message and keeps email pre-filled" do
    previous_path = current_path
    fill_in "Email address", with: @user.email
    fill_in "Password", with: "wrong"
    click_text "Log In"

    sleep 0.1
    assert_text "Invalid email or password"
    assert_equal @user.email, find("#email").value
    assert_active "#password"
    assert_current_path previous_path, ignore_query: true
  end

  test "should NOT display a Google button when the feature is DISABLED" do
    stub_features(google_authentication: false) do
      visit root_url
      assert_no_text "Log In with Google"
    end
  end

  test "should SHOW the Google button when the feature is ENABLED" do
    stub_features(google_authentication: true) do
      visit root_url
      assert_text "Log In with Google"
    end
  end

  test "should SHOW the Microsoft button when the feature is ENABLED" do
    stub_features(microsoft_graph_authentication: true) do
      visit root_url
      assert_text "Log In with Microsoft"
    end
  end

  test "should NOT display a Microsoft button when the feature is DISABLED" do
    stub_features(microsoft_graph_authentication: false) do
      visit root_url
      assert_no_text "Log In with Microsoft"
    end
  end
end
