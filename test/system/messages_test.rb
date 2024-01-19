require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
  setup do
    @message = messages(:hear_me)
    login_as @message.conversation.user
  end
end
