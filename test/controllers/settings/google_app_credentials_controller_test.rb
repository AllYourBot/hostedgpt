require "test_helper"

class Settings::GoogleAppCredentialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:keith)
    login_as @user
  end

  test "should destroy gmail credential and leave the other Google connections alone" do
    assert_difference "Credential.count", -1 do
      delete settings_google_app_credential_url(credentials(:keith_gmail))
    end

    assert_redirected_to edit_settings_person_url
    assert_equal "Disconnected", flash[:notice], "The user should be told the connection was removed"
    assert_nil @user.reload.gmail_credential, "Gmail should no longer be connected"
    assert @user.google_tasks_credential.present?, "Google Tasks should still be connected"
    assert @user.google_calendar_credential.present?, "Google Calendar should still be connected"
  end

  test "should destroy google tasks and google calendar credentials" do
    delete settings_google_app_credential_url(credentials(:keith_google_tasks))
    assert_nil @user.reload.google_tasks_credential, "Google Tasks should no longer be connected"

    delete settings_google_app_credential_url(credentials(:keith_google_calendar))
    assert_nil @user.reload.google_calendar_credential, "Google Calendar should no longer be connected"
  end

  test "should not call Google when disconnecting" do
    SDK::Post.stub :new, ->(*) { raise "should not call Google" } do
      delete settings_google_app_credential_url(credentials(:keith_gmail))
    end

    assert_redirected_to edit_settings_person_url
    assert_nil @user.reload.gmail_credential, "Gmail should no longer be connected"
  end

  test "should not destroy a LOGIN credential" do
    %i[keith_password keith_google keith_microsoft_graph].each do |name|
      assert_no_difference "Credential.count", "#{name} should not be destroyed" do
        delete settings_google_app_credential_url(credentials(name))
      end

      assert_redirected_to edit_settings_person_url
      assert_equal "The connection could not be found", flash[:alert], "#{name} should be reported as not found"
    end
  end

  test "should not destroy ANOTHER USER'S credential" do
    get logout_url
    login_as users(:rob)

    assert_no_difference "Credential.count" do
      delete settings_google_app_credential_url(credentials(:keith_gmail))
    end

    assert_redirected_to edit_settings_person_url
    assert_equal "The connection could not be found", flash[:alert], "Another user's connection should be reported as not found"
    assert users(:keith).reload.gmail_credential.present?, "Keith's Gmail should still be connected"
  end
end
