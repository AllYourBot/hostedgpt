class Redcarpet::CustomHtmlRenderer < Redcarpet::Render::HTML
  def paragraph(text)
    text.gsub!("\n", "<br>\n")
    "\n<p>#{text}</p>\n"
  end

  def codespan(code)
    "<code>#{code}</code>"
  end
end
