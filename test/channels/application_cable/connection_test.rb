require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    test "connecting does not add a subscription-confirmation listener" do
      assert_no_difference -> { ActiveSupport::Notifications.notifier.listeners_for("transmit_subscription_confirmation.action_cable").size } do
        2.times { connect }
      end
    end
  end
end
