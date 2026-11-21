class IPLocation < SDK
  def self.name_for(ip) = new.name_for(ip)

  def name_for(ip)
    return if ip.blank?

    place = get_location(ip)
    return if place.try(:bogon)

    [place.try(:city), place.try(:region), place.try(:country)].compact_blank.uniq.join(", ").presence
  rescue => e
    Rails.logger.info "IP location lookup failed: #{e.class} #{e.message}"
    nil
  end

  private

  def get_location(ip) = get("https://ipinfo.io/#{ERB::Util.url_encode(ip)}/json").no_params
end
