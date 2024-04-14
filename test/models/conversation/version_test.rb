require "test_helper"

class Conversation::VersionTest < ActiveSupport::TestCase
  test "latest_message works" do
    assert_equal messages(:im_a_bot), conversations(:greeting).latest_message
  end

  test "latest_version_for_message_index" do
    assert_equal 1, conversations(:versioned).latest_version_for_message_index(1)
    assert_equal 2, conversations(:versioned).latest_version_for_message_index(3)
  end
end
