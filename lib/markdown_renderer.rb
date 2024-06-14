Dir[File.join(File.dirname(__FILE__), 'redcarpet', '*.rb')].each { |file| require file }

class MarkdownRenderer
  class << self
    def render_for_speaking(markdown)
      Redcarpet::CustomSpeakingRenderer.new.render(markdown.to_s)
    end

    def render_for_display(markdown, options = {})
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
      formatter.render(markdown)
    end

    private

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
