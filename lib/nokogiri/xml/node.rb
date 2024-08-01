class Nokogiri::XML::Node
  def at_id(id)
    at_css("##{id}")
  end
end
