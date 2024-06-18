require "test_helper"

class Toolbox::GmailTest < ActiveSupport::TestCase
  setup do
    @gmail = Toolbox::Gmail.new
  end

  test "email_myself" do
    stub_get_response(status: 200, **user_profile_data) do
      Current.set(user: users(:keith)) do
        assert_equal user_profile_data, @gmail.send(:get_user_profile).to_h
      end
    end
  end

  private

  def user_profile_data
    { emailAddress: "krschacht@gmail.com", messagesTotal: 876831, threadsTotal: 537585, historyId: 74273500 }
  end
end
