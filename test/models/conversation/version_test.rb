require "test_helper"

class Conversation::VersionTest < ActiveSupport::TestCase
  test "latest_message_for_version" do
    assert_equal messages(:message3_v1), conversations(:versioned).latest_message_for_version(1)
    assert_equal messages(:message5_v2), conversations(:versioned).latest_message_for_version(2)
  end

  test "latest_version_for_message_index" do
    assert_equal 1, conversations(:versioned).latest_version_for_message_index(1)
    assert_equal 2, conversations(:versioned).latest_version_for_message_index(3)
  end
end
