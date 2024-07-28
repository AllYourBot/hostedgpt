require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @person = people(:keith_registered)
    users(:keith)
    credentials(:keith_password)

    @settings = {
      postmark_from_email: "teampeople@example.com",
      product_name: "Product Name"
    }
    @features = {
      password_reset_email: true,
      email_sender_postmark: true
    }
  end

  test "should get new" do
    stub_settings_and_features do
      get new_password_reset_url

      assert_response :success
    end
  end

  test "should post create" do
    # set user agent to simulate a browser
    browser = "Chrome"
    operating_system = "Windows"

    email = @person.email

    stub_settings_and_features do
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
end
