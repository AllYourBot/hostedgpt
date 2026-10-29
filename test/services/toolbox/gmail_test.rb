require "test_helper"

class Toolbox::GmailTest < ActiveSupport::TestCase
  setup do
    skip
    @gmail = Toolbox::Gmail.new
  end

  test "email_myself" do
    stub_get_response(:get_user_profile, status: 200, response: user_profile_data) do
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

class Toolbox::GmailEmptyMailboxTest < ActiveSupport::TestCase
  # Gmail leaves out the "threads" and "messages" keys when nothing matches the query.
  test "check_inbox on an empty mailbox with no sent mail" do
    gmail = Toolbox::Gmail.new

    empty_response = ->(*) { OpenStruct.new }

    gmail.stub(:refresh_token_if_needed, empty_response) do
      result = gmail.check_inbox

      assert_equal 0, result[:messages_in_inbox]
      assert_equal 0, result[:unread_messages_in_inbox]
      assert_equal 0, result[:read_messages_in_inbox]
      assert_equal({}, result[:most_recent_message])
      assert_equal({}, result[:last_sent_message])
    end
  end
end
