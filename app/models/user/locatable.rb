module User::Locatable
  extend ActiveSupport::Concern

  included do
    store_accessor :preferences, :use_ip_location, :ip_location

    # In the included block so these override store_accessor's methods rather than being shadowed by them.
    def use_ip_location? = use_ip_location.to_b

    def use_ip_location=(value)
      super(value.nil? ? nil : value.to_b)
      self.ip_location = nil unless use_ip_location?
    end
  end

  def located_at!(ip)
    return unless use_ip_location?
    return if ip.blank? || ip_location&.dig("ip") == ip

    update!(ip_location: { "ip" => ip })
  end

  def location
    return unless use_ip_location? && ip_location&.dig("ip")
    return ip_location["name"] if ip_location.key?("name")

    IPLocation.name_for(ip_location["ip"]).tap do |name|
      update!(ip_location: ip_location.merge("name" => name))
    end
  end
end
