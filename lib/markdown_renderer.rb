require "./lib/redcarpet/custom_html_renderer"

class MarkdownRenderer

  def self.render(markdown, options = {})
    markdown ||= ""

    render_class = Redcarpet::CustomHtmlRenderer

    block_code_proc = options.delete(:block_code)

    if block_code_proc

      render_class = Class.new(Redcarpet::CustomHtmlRenderer)
      render_class.instance_eval do
        define_method(:block_code) do |code, language|
          block_code_proc.call(code.html_safe, language)
        end
      end
    end

    renderer = render_class.new(safe_links_only: true)

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

    markdown = ensure_newline_before_code_block_start(markdown)

    formatter.render(markdown)
  end

  def self.ensure_newline_before_code_block_start(markdown)
    markdown.gsub(/(?<!\n\n)(?<=^[ \t]{0,3})```.*?```/m, "\n\\0")
  end
end
