require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    test "connects with cookies" do
      connect params: { user_id: 42 }

      assert_equal connection.user_id, "42"
    end
  end
end
