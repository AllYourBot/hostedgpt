require "test_helper"

class Toolbox::GmailTest < ActiveSupport::TestCase
  setup do
    @gmail = Toolbox::Gmail.new
  end

  test "get_user_profile returns the profile from the API" do
    stub_get_response(:get_user_profile, status: 200, response: user_profile_data) do
      Current.set(user: users(:keith)) do
        assert_equal user_profile_data, @gmail.send(:get_user_profile).to_h, "Should return the Gmail profile from the API"
      end
    end
  end

  test "check_inbox on an empty mailbox with no sent mail" do
    response_without_threads_or_messages = ->(*) { OpenStruct.new }

    @gmail.stub(:refresh_token_if_needed, response_without_threads_or_messages) do
      result = @gmail.check_inbox

      assert_equal 0, result[:messages_in_inbox], "An empty inbox should count no messages"
      assert_equal 0, result[:unread_messages_in_inbox], "An empty inbox should count no unread messages"
      assert_equal 0, result[:read_messages_in_inbox], "An empty inbox should count no read messages"
      assert_equal({}, result[:most_recent_message], "An empty inbox should have no most recent message")
      assert_equal({}, result[:last_sent_message], "No sent mail should mean no last sent message")
    end
  end

  private

  def user_profile_data
    { emailAddress: "krschacht@gmail.com", messagesTotal: 876831, threadsTotal: 537585, historyId: 74273500 }
  end
end
