require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @person = people(:keith_registered)
    users(:keith)
    credentials(:keith_password)
  end

  test "should get new" do
    get new_password_reset_url

    assert_response :success
  end

  test "should post create" do
    # set user agent to simulate a browser
    browser = "Chrome"
    operating_system = "Windows"

    email = @person.email

    # set the user agent in the request headers
    ActionDispatch::Request.stub_any_instance(:user_agent, "#{browser} on #{operating_system}") do
      post password_resets_url, params: { email: email }
    end

    assert_enqueued_jobs 1
    assert_enqueued_with(job: SendResetPasswordEmailJob, args: [email, operating_system, browser])
    assert_response :redirect
    assert_redirected_to login_path
  end
end
