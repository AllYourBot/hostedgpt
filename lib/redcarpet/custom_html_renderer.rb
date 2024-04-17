class Redcarpet::CustomHtmlRenderer < Redcarpet::Render::HTML
  def initialize(options={})
    super(options.merge(filter_html: false))
  end
  def paragraph(text)
    text.gsub!("\n", "<br>\n")
    "\n<p>#{text}</p>\n"
  end

  def codespan(code)
    "<code>#{code}</code>"
  end

  def block_code(code, language)
    code
  end

end
