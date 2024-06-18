require "test_helper"

class Toolbox::GmailTest < ActiveSupport::TestCase
  setup do
    @gmail = Toolbox::Gmail.new
  end

  test "email_myself" do
    # Not sure if it's worth stubbing out API responses for these methods.
    #
    # Current.set(user: users(:keith)) do
    #   @gmail.email_myself(message_s: "Pick up some milk")
    # end
  end
end
