class Redcarpet::CustomHtmlRenderer < Redcarpet::Render::HTML
  def codespan(code)
    %(<code><span class="hidden">`</span>#{code}<span class="hidden">`</span></code>)
  end
end
