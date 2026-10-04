# Subscribe once at boot: a subscription made per connection is process-wide and never removed.
ActiveSupport::Notifications.subscribe("transmit_subscription_confirmation.action_cable") do |event|
  ApplicationCable::LatestMessageRebroadcast.call(event.payload)
end
