require "test_helper"

module ApplicationCable
  class LatestMessageRebroadcastTest < ActiveSupport::TestCase
    setup do
      @conversation = conversations(:greeting)
      @identifier = { channel: "Turbo::StreamsChannel", signed_stream_name: Turbo::StreamsChannel.signed_stream_name(@conversation) }.to_json
    end

    test "a confirmed turbo stream subscription re-broadcasts the conversation's latest message exactly once" do
      broadcasted = []
      GetNextAIMessageJob.stub :broadcast_updated_message, ->(message) { broadcasted << message } do
        ActiveSupport::Notifications.instrument("transmit_subscription_confirmation.action_cable",
          channel_class: "Turbo::StreamsChannel", identifier: @identifier)
      end

      assert_equal [@conversation.latest_message_for_version], broadcasted, "The latest message should be re-broadcast exactly once"
    end

    test "other channels are ignored" do
      GetNextAIMessageJob.stub :broadcast_updated_message, ->(_) { flunk "should not re-broadcast" } do
        assert_nil LatestMessageRebroadcast.call(channel_class: "OtherChannel", identifier: @identifier), "A non-Turbo channel should be skipped"
      end
    end
  end
end
