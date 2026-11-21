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

    remember_ip_location("ip" => ip)
  end

  def location
    return unless use_ip_location? && ip_location&.dig("ip")
    return ip_location["name"] if ip_location.key?("name")

    IPLocation.name_for(ip_location["ip"]).tap do |name|
      remember_ip_location(ip_location.merge("name" => name))
    end
  end

  private

  # Sets only this key in the database: saving the whole preferences hash from this possibly stale user
  # would undo any preference changed since it was loaded.
  def remember_ip_location(value)
    User.where(id:).update_all(
      ["preferences = jsonb_set(coalesce(preferences, '{}'::jsonb), '{ip_location}', ?::jsonb)", value.to_json]
    )
    self.ip_location = value
    clear_attribute_change(:preferences)
  end
end
