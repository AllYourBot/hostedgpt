# Sometimes the conversation page loads and it doesn't get the message to appear, even though
# the logs show it was broadcasted. This is because there is a small race condition where right
# in between when find() of the message and the client establishing the turbo stream connection,
# the broadcast happens.
#
# The fix is to re-broadcast the last message to the client after the subscription is confirmed.
# config/initializers/action_cable_rebroadcast.rb subscribes to that confirmation once per process.
#
# FIXME: See if there is any conclusion on this Rails Issue: https://github.com/rails/rails/issues/52420
module ApplicationCable
  class LatestMessageRebroadcast
    def self.call(payload)
      return unless payload[:channel_class] == "Turbo::StreamsChannel"

      signed_stream_name = JSON.parse(payload[:identifier])["signed_stream_name"]
      stream_name = Base64.urlsafe_decode64(Turbo.signed_stream_verifier.verify(signed_stream_name))
      class_name, id = stream_name.split("/").last(2)
      conversation = class_name.classify.constantize.find(id)

      GetNextAIMessageJob.broadcast_updated_message(conversation.latest_message_for_version)
    end
  end
end
