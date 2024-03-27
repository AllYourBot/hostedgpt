require "./lib/markdown_renderer"

module MessagesHelper
  def format(text)

    # text = html_escape(text)

    # if text.include?('`')
    #   text = paired_single_backticks(text)
    #   text = paired_triple_backticks(text)
    #   text = copy_button(text)
    # end

    # return text.html_safe



    # renderer = Redcarpet::Render::HTML.new(safe_links_only: true)
    # formatter = Redcarpet::Markdown.new(renderer,
    #   autolink: true,
    #   tables: true,
    #   space_after_headers: true,
    #   strikethrough: true,
    #   underline: true,
    #   no_intra_emphasis: true,

    #   fenced_code_blocks: true,
    #   disable_indented_code_blocks: true
    # )

    # return formatter.render(text).html_safe



    block_code = ->(code, language) do
      content_tag(:pre,
        class: %|
          p-0 m-0
          #{"language-#{language}" if language}
        |,
        data: {
          controller: "clipboard transition",
          transition_toggle_class: "hidden"
      }) do
        div_tag(class: %|
          px-4 py-2
          text-xs font-sans
          bg-gray-600 text-gray-300
          flex justify-between items-center
          clipboard-exclude
        |) do
          span_tag(language) +
          button_tag(type: "button",
            class: %|
              cursor-pointer
              hover:text-white dark:hover:text-white
              flex items-center
            |,
            data: {
              role: "code-clipboard",
              action: %|
                clipboard#copy
                transition#toggleClassOn
                mouseleave->transition#toggleClassOff
              |,
              keyboard_target: "keyboardable",
          }) do
            icon("clipboard", variant: :outline, size: 16, data: { transition_target: "transitionable" }, class: "-mt-[1px]") +
            span_tag("Copy code", data: { transition_target: "transitionable" }, class: "ml-1") +
            icon("check",     variant: :outline, size: 16, data: { transition_target: "transitionable" }, class: "hidden") +
            span_tag("Copied!", data: { transition_target: "transitionable" }, class: "hidden ml-1")
          end
        end +
        div_tag(class: "px-4 py-3") do
          span_tag("```#{language}\n", class: "hidden") +
          content_tag(:code, code, data: { clipboard_target: "text" }) +
          span_tag("```\n", class: "hidden")
        end
      end

      # <<~END
      #   <pre
      #     data-controller="clipboard transition"
      #     data-transition-toggle-class="hidden"
      #     class="p-0 m-0 #{"language-#{language}" if language}"
      #   ><div class='
      #       px-4 py-2
      #       text-xs font-sans
      #       bg-gray-600 text-gray-300
      #       flex justify-between items-center
      #       clipboard-exclude
      #       '><span>#{language}</span
      #       ><span>#{
      #         button_tag(type: "button",
      #           class: %|
      #             cursor-pointer
      #             hover:text-white dark:hover:text-white
      #             flex items-center
      #           |,
      #           data: {
      #             role: "code-clipboard",
      #             action: %|
      #               clipboard#copy
      #               transition#toggleClassOn
      #               mouseleave->transition#toggleClassOff
      #             |,
      #             keyboard_target: "keyboardable",
      #         }) do
      #           icon("clipboard", variant: :outline, size: 16, data: { transition_target: "transitionable" }, class: "-mt-[1px]") +
      #           content_tag(:span, "Copy code", data: { transition_target: "transitionable" }, class: "ml-1") +
      #           icon("check",     variant: :outline, size: 16, data: { transition_target: "transitionable" }, class: "hidden") +
      #           content_tag(:span, "Copied!", data: { transition_target: "transitionable" }, class: "hidden ml-1")
      #         end
      #       }</span></div
      #     ><div class="px-4 py-3"
      #       ><span class="hidden">```#{language}#{"\n"}</span
      #       ><code data-clipboard-target="text" class="">#{code}</code
      #       ><span class="hidden">```#{"\n"}</span
      #     ></div
      #   ></pre>
      # END
    end

    return ::MarkdownRenderer.render(text,
      block_code: block_code
    ).html_safe
  end

  def paired_single_backticks(text)
    text.gsub(/(?<!`)(`)(?=[^`]*`)([^`]+)`(?!`)/,
      '<code><span class="hidden">`</span>\2<span class="hidden">`</span></code>')
  end

  def paired_triple_backticks(text)
    text.gsub(/(?<!`)(```)([a-zA-Z0-9]*)(?:\n)?((?:\n?.*?)*)```(?!`)(?:\n)?/m) do
      language = $2
      content = $3
      text = <<~END
        <pre
          data-controller="clipboard transition"
          data-transition-toggle-class="hidden"
          class="p-0 m-0 #{"language-#{language}" if language}"
        ><div class='
            px-4 py-2
            text-xs font-sans
            bg-gray-600 text-gray-300
            flex justify-between items-center
            clipboard-exclude
            '><span>#{language}</span
            ><span>BUTTON_TAG</span></div
          ><div class="px-4 py-3"
            ><span class="hidden">```#{language}#{"\n"}</span
            ><code data-clipboard-target="text" class="">#{content}</code
            ><span class="hidden">```#{"\n"}</span
          ></div
        ></pre>
      END
      text.strip
    end
  end

  def copy_button(text)
    text.gsub('BUTTON_TAG',
      button_tag(type: "button",
        class: %|
          cursor-pointer
          hover:text-white dark:hover:text-white
          flex items-center
        |,
        data: {
          role: "code-clipboard",
          action: %|
            clipboard#copy
            transition#toggleClassOn
            mouseleave->transition#toggleClassOff
          |,
          keyboard_target: "keyboardable",
      }) do
        icon("clipboard", variant: :outline, size: 16, data: { transition_target: "transitionable" }, class: "-mt-[1px]") +
        content_tag(:span, "Copy code", data: { transition_target: "transitionable" }, class: "ml-1") +
        icon("check",     variant: :outline, size: 16, data: { transition_target: "transitionable" }, class: "hidden") +
        content_tag(:span, "Copied!", data: { transition_target: "transitionable" }, class: "hidden ml-1")
      end
    )
  end
end
