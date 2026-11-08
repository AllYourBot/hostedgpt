require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:keith)
    @user = users(:rob)
  end

  test "should get index listing every user" do
    login_as @admin
    get admin_users_url
    assert_response :success
    assert_select "#users tbody tr", User.count, "Every user should be listed"
    assert_contains_text "##{dom_id(@user)}", @user.email
    assert_select "##{dom_id(@admin)} [data-role=admin] svg", 1, "The admin should be marked as an admin"
    assert_select "##{dom_id(@user)} [data-role=admin] svg", 0, "A regular user should not be marked as an admin"
    assert_select "a[href=?]", edit_admin_user_path(@user), 1, "Each user should have an edit link"
  end

  test "should show the Admin menu item in settings when user IS an admin" do
    login_as @admin
    get edit_settings_person_url
    assert_select "#menu a[href=?]", admin_users_path, 1, "An admin should see the Admin menu item"
  end

  test "should hide the Admin menu item in settings when user IS NOT an admin" do
    login_as @user
    get edit_settings_person_url
    assert_select "#menu a[href=?]", admin_users_path, 0, "A regular user should not see the Admin menu item"
  end

  test "should return not found for index when user IS NOT an admin" do
    login_as @user
    get admin_users_url
    assert_response :not_found
  end

  test "should get new user" do
    login_as @admin
    get new_admin_user_url
    assert_response :success
    assert_select "form[action=?][method=post]", admin_users_path
    assert_select "input[type=password][name=?]", "person[personable_attributes][credentials_attributes][0][password]", 1,
      "A password field should be shown"
    assert_select "input[type=checkbox][name=?]:not([disabled])", "person[personable_attributes][admin]"
  end

  test "should get new user WITHOUT a password field when password authentication IS DISABLED" do
    login_as @admin
    stub_features(password_authentication: false) do
      get new_admin_user_url
    end
    assert_response :success
    assert_select "input[type=password]", 0, "No password field should be shown"
  end

  test "should create user who can log in with their password" do
    login_as @admin
    assert_difference "User.count", 1 do
      post admin_users_url, params: { person: {
        email: "ali@example.com",
        personable_attributes: {
          first_name: "Ali", last_name: "Smith", admin: "1", dark_mode: "dark", show_thinking: "0",
          credentials_attributes: { "0" => { password: "secret123" } }
        }
      } }
    end

    assert_redirected_to admin_users_url
    assert flash[:notice].present?, "There should be a flash notice"
    user = Person.find_by(email: "ali@example.com").user
    assert_equal ["Ali", "Smith"], [user.first_name, user.last_name], "The name should be saved"
    assert user.admin?, "The user should be an admin"
    assert_equal "dark", user.dark_mode, "The theme should be saved"
    refute user.show_thinking?, "Show thinking should be off"
    assert user.password_credential.authenticate("secret123"), "The user should be able to log in with the password"
    assert user.api_services.any?, "The user should get the default API services, like any new registration"
  end

  test "should create user WITHOUT a password when password authentication IS DISABLED" do
    login_as @admin
    stub_features(password_authentication: false) do
      assert_difference "User.count", 1 do
        post admin_users_url, params: { person: {
          email: "ali@example.com",
          personable_attributes: { first_name: "Ali", last_name: "Smith", credentials_attributes: { "0" => { password: "secret123" } } }
        } }
      end
    end

    assert_redirected_to admin_users_url
    assert_nil Person.find_by(email: "ali@example.com").user.password_credential, "No password credential should be created"
  end

  test "should render new with errors when create IS INVALID" do
    login_as @admin
    assert_no_difference "User.count" do
      post admin_users_url, params: { person: {
        email: "not-an-email",
        personable_attributes: { first_name: "", last_name: "Smith", credentials_attributes: { "0" => { password: "" } } }
      } }
    end

    assert_response :unprocessable_content
    assert_select "#error_explanation li", { minimum: 2 }, "Each error should be listed"
    assert_select "form[action=?]", admin_users_path, 1, "The new form should be shown again"
  end

  test "should return not found for create when user IS NOT an admin" do
    login_as @user
    assert_no_difference "User.count" do
      post admin_users_url, params: { person: { email: "ali@example.com", personable_attributes: { first_name: "Ali", last_name: "Smith" } } }
    end
    assert_response :not_found
  end

  test "should edit user" do
    login_as @admin
    get edit_admin_user_url(@user)
    assert_response :success
    assert_select "input[name=?][value=?]", "person[email]", @user.email
    assert_select "input[name=?][value=?]", "person[personable_attributes][first_name]", @user.first_name
    assert_select "input[type=checkbox][name=?]:not([disabled])", "person[personable_attributes][admin]"
  end

  test "should edit self with the admin checkbox DISABLED" do
    login_as @admin
    get edit_admin_user_url(@admin)
    assert_response :success
    assert_select "input[type=checkbox][name=?][disabled]", "person[personable_attributes][admin]"
    assert_contains_text "form", "You can't remove your own admin rights"
  end

  test "should update user" do
    login_as @admin
    patch admin_user_url(@user), params: { person: {
      email: "robert@hostedgpt.com",
      personable_attributes: { first_name: "Robert", last_name: "Smith", admin: "1" }
    } }

    assert_redirected_to admin_users_url
    assert flash[:notice].present?, "There should be a flash notice"
    @user.reload
    assert_equal "robert@hostedgpt.com", @user.email, "The email should be updated"
    assert_equal "Robert", @user.first_name, "The first name should be updated"
    assert_equal "Smith", @user.last_name, "The last name should be updated"
    assert @user.admin?, "The user should now be an admin"
  end

  test "should edit user preferences" do
    @user.update!(dark_mode: "dark", show_thinking: false, provider_web_search: true)
    login_as @admin
    get edit_admin_user_url(@user)
    assert_response :success
    assert_select "input[type=radio][name=?][value=dark][checked]", "person[personable_attributes][dark_mode]", 1,
      "The user's own theme should be selected, not the admin's"
    assert_select "input[type=checkbox][name=?]:not([checked])", "person[personable_attributes][show_thinking]", 1,
      "Show thinking should be unchecked"
    assert_select "input[type=checkbox][name=?][checked]", "person[personable_attributes][ask_follow_ups]", 1,
      "Ask follow-ups should default to checked"
    assert_select "input[type=checkbox][name=?][checked]", "person[personable_attributes][provider_web_search]", 1,
      "Web search should be checked"
  end

  test "should update user preferences" do
    login_as @admin
    patch admin_user_url(@user), params: { person: { personable_attributes: {
      dark_mode: "light", show_thinking: "0", ask_follow_ups: "0", provider_web_search: "1"
    } } }

    assert_redirected_to admin_users_url
    @user.reload
    assert_equal "light", @user.dark_mode, "The theme should be updated"
    refute @user.show_thinking?, "Show thinking should be off"
    refute @user.ask_follow_ups?, "Ask follow-ups should be off"
    assert @user.provider_web_search?, "Web search should be on"
  end

  test "should update the user in the url EVEN IF params name another user" do
    login_as @admin
    patch admin_user_url(@user), params: { person: { personable_attributes: { id: @admin.id, first_name: "Robert" } } }

    assert_redirected_to admin_users_url
    assert_equal "Robert", @user.reload.first_name, "The user in the url should be updated"
    assert_equal "Keith", @admin.reload.first_name, "The user named in the params should be untouched"
  end

  test "should NOT let an admin revoke their own admin rights" do
    login_as @admin
    patch admin_user_url(@admin), params: { person: { personable_attributes: { first_name: "Keith", admin: "0" } } }

    assert_redirected_to admin_users_url
    assert @admin.reload.admin?, "The admin should still be an admin"
  end

  test "should render edit with errors when update IS INVALID" do
    login_as @admin
    patch admin_user_url(@user), params: { person: { email: "not-an-email", personable_attributes: { first_name: "" } } }

    assert_response :unprocessable_content
    assert_select "#error_explanation", 1, "The errors should be shown"
    assert_equal "rob@hostedgpt.com", @user.reload.email, "The email should be unchanged"
  end

  test "should return not found for update when user IS NOT an admin" do
    login_as @user
    patch admin_user_url(@admin), params: { person: { personable_attributes: { admin: "0" } } }

    assert_response :not_found
    assert @admin.reload.admin?, "The admin should be untouched"
  end

  test "should show a delete button on edit for ANOTHER user but not for self" do
    login_as @admin
    get edit_admin_user_url(@user)
    assert_select "form[action=?] input[name=_method][value=delete]", admin_user_path(@user), 1, "Another user should have a delete button"

    get edit_admin_user_url(@admin)
    assert_select "form[action=?] input[name=_method][value=delete]", admin_user_path(@admin), 0, "The admin should not be offered to delete themself"
  end

  test "should destroy user along with their data" do
    login_as @admin
    person = @user.person
    assert @user.conversations.any? || @user.api_services.any?, "The user should have data to delete"

    assert_difference "User.count", -1 do
      delete admin_user_url(@user)
    end

    assert_redirected_to admin_users_url
    assert flash[:notice].present?, "There should be a flash notice"
    refute Person.exists?(person.id), "The person should be deleted"
    assert_equal 0, APIService.where(user_id: @user.id).count, "The user's API services should be deleted"
    assert_equal 0, Conversation.where(user_id: @user.id).count, "The user's conversations should be deleted"
  end

  test "should NOT let an admin delete themself" do
    login_as @admin
    assert_no_difference "User.count" do
      delete admin_user_url(@admin)
    end

    assert_redirected_to edit_admin_user_url(@admin)
    assert flash[:alert].present?, "There should be a flash alert"
  end

  test "should return not found for destroy when user IS NOT an admin" do
    login_as @user
    assert_no_difference "User.count" do
      delete admin_user_url(@admin)
    end
    assert_response :not_found
  end
end
