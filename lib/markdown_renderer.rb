require "commonmarker"
require "nokogiri"

class MarkdownRenderer
  COMMONMARKER_EXTENSIONS = {
    strikethrough: true,
    tagfilter: true,
    table: true,
    autolink: true,
    tasklist: true,
    alerts: true,
    underline: true,
  }.freeze

  class << self
    def render_for_speaking(markdown)
      CustomSpeakingRenderer.new.render(markdown.to_s)
    end

    def render_for_display(markdown, options = {})
      # Input contract: content arrives HTML-escaped once upstream (the XSS
      # contract lives at the helper). This layer parses markdown; it does
      # not escape raw markup itself.
      block_code_proc = options.delete(:block_code)

      markdown = ensure_blank_line_before_code_block_start(markdown)
      markdown, math_spans = extract_math_spans(markdown)
      markdown = markdown.dup.force_encoding(Encoding::UTF_8).scrub
      html = Commonmarker.to_html(
        markdown,
        options: { extension: COMMONMARKER_EXTENSIONS },
        plugins: { syntax_highlighter: nil }
      )
      html = apply_block_code_proc(html, block_code_proc) if block_code_proc
      restore_math_spans(html, math_spans)
    end

    private

    def extract_math_spans(markdown)
      spans = []
      markdown = markdown.gsub(/\\\\\((.+?)\\\\\)|\\\\\[(.+?)\\\\\]/m) do |m|
        lift_math_span(spans, "\\(#{m[3..-4]}\\)")
      end
      markdown = markdown.gsub(/\$\$.+?\$\$/m) { |m| lift_math_span(spans, m) }
      markdown = markdown.gsub(/\\\(.+?\\\)|\\\[.+?\\\]/m) { |m| lift_math_span(spans, m) }
      [ markdown, spans ]
    end

    # A candidate span containing a fence sequence is left raw: lifting it
    # would swallow the fence closer (and everything after) into one
    # unterminated code block. Doubled-backslash delimiters from models are
    # normalized to the single form so KaTeX pairs them.
    def lift_math_span(spans, span)
      if span.include?("```")
        span
      else
        spans << span
        math_placeholder(spans.size - 1)
      end
    end

    def restore_math_spans(html, spans)
      html.gsub(/#{Regexp.escape(math_placeholder_delimiter)}(\d+)#{Regexp.escape(math_placeholder_delimiter)}/) do
        spans[Regexp.last_match(1).to_i]
      end
    end

    def math_placeholder(index)
      "#{math_placeholder_delimiter}#{index}#{math_placeholder_delimiter}"
    end

    # Private-use characters delimit the placeholder: no markdown syntax or
    # plausible model output collides with them, unlike an ASCII token.
    def math_placeholder_delimiter
      "\uE000"
    end

    # Commonmarker has no block_code callback, so the helper's copy-header
    # structure is applied as a post-process: each <pre> is replaced by
    # whatever the proc returns for its (code_html, language).
    def apply_block_code_proc(html, block_code_proc)
      return html unless html.include?("<pre")

      doc = Nokogiri::HTML.fragment(html)
      doc.css("pre").each do |pre|
        code = pre.at_css("code") || pre
        language = pre["lang"] || code["class"].to_s[/language-(\S+)/, 1]
        code_html = (code == pre ? pre.inner_html : code.inner_html)
        pre.replace(Nokogiri::HTML.fragment(block_code_proc.call(code_html.html_safe, language)))
      end
      doc.to_html
    end

    def ensure_blank_line_before_code_block_start(markdown)
      markdown.to_s.gsub(/(\n*)( *)(```.*?```)/m, "\n\n\\2\\3")
    end
  end
end
