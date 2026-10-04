# Subscribed once at boot, not per connection: a subscription made in Connection#connect is
# process-wide and never removed, so every page load would add another re-broadcast.
ActiveSupport::Notifications.subscribe("transmit_subscription_confirmation.action_cable") do |event|
  ApplicationCable::LatestMessageRebroadcast.call(event.payload)
end
