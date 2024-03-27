require "./lib/markdown_renderer"

module MessagesHelper
  def format(text)
    safe_html = ::MarkdownRenderer.render(
      text,
      block_code: block_code
    ).html_safe

    return safe_html
  end

  private

  def block_code
    ->(code, language) do
      content_tag(:pre,
        class: %|
          p-0
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
          content_tag(:code, code, data: { clipboard_target: "text" })
        end
      end
    end
  end
end
