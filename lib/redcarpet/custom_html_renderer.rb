class Redcarpet::CustomHtmlRenderer < Redcarpet::Render::HTML
  def paragraph(text)
    text.gsub!("\n", "<br>\n")
    "\n<p>#{text}</p>\n"
  end
end
