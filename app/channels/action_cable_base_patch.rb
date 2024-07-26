module ActionCableBasePatch
  def self.included(base)
    base.class_eval do
      def transmit_subscription_confirmation
        unless subscription_confirmation_sent?
          logger.debug "#{self.class.name} is transmitting the subscription confirmation"

          ActiveSupport::Notifications.instrument("transmit_subscription_confirmation.action_cable", channel_class: self.class.name, identifier: @identifier) do
            connection.transmit identifier: @identifier, type: ActionCable::INTERNAL[:message_types][:confirmation]
            @subscription_confirmation_sent = true
          end
        end
      end
      private :transmit_subscription_confirmation
    end
  end
end
