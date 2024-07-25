module ApplicationCable
  class Connection < ActionCable::Connection::Base
    def connect
      ActiveSupport::Notifications.subscribe "transmit_subscription_confirmation.action_cable" do |*args|
        # Sometimes the conversation page loads and it doesn't get the message to appear, even though
        # the logs show it was broadcasted. This is because there is a small race condition where right
        # in between when find() of the message and the client establishing the turbo stream connection,
        # the broadcast happens.
        #
        # The fix is to re-broadcast the last message to the client after the connection is established.
        event = ActiveSupport::Notifications::Event.new(*args)

        if event.payload[:channel_class] == "Turbo::StreamsChannel"
          identifier = JSON.parse(event.payload[:identifier])
          signed_stream_name = identifier["signed_stream_name"]
          stream_name = Base64.urlsafe_decode64(Turbo.signed_stream_verifier.verify(signed_stream_name))
          class_name, id = stream_name.split("/").last(2)
          conversation = class_name.classify.constantize.find(id)
          message = conversation.latest_message_for_version

          GetNextAIMessageJob.broadcast_updated_message(message)
        end
      end
    end
  end
end
