Dir[File.join(File.dirname(__FILE__), "redcarpet", "*.rb")].each { |file| require file }

class MarkdownRenderer
  class << self
    def render_for_speaking(markdown)
      Redcarpet::CustomSpeakingRenderer.new.render(markdown.to_s)
    end

    def render_for_display(markdown, options = {})
      # Input contract: content arrives HTML-escaped once upstream (the XSS
      # contract lives at the helper). This layer parses markdown; it does
      # not escape raw markup itself.
      renderer  = create_renderer_for_display(options)
      formatter = Redcarpet::Markdown.new(renderer,
        autolink: true,
        tables: true,
        space_after_headers: true,
        strikethrough: true,
        underline: true,
        no_intra_emphasis: true,
        fenced_code_blocks: true,
        disable_indented_code_blocks: true
      )

      markdown = ensure_blank_line_before_code_block_start(markdown)
      markdown, math_spans = extract_math_spans(markdown)
      html = formatter.render(markdown)
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

    def create_renderer_for_display(options)
      render_class = Redcarpet::CustomDisplayRenderer

      block_code_proc = options.delete(:block_code)
      if block_code_proc
        render_class = Class.new(Redcarpet::CustomDisplayRenderer)
        render_class.instance_eval do
          define_method(:block_code) do |code, language|
            block_code_proc.call(code.html_safe, language)
          end
        end
      end

      render_class.new(safe_links_only: true)
    end

    def ensure_blank_line_before_code_block_start(markdown)
      markdown.to_s.gsub(/(\n*)( *)(```.*?```)/m, "\n\n\\2\\3")
    end
  end
end
