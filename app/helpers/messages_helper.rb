require "./lib/markdown_renderer"

module MessagesHelper
  def render_avatar_for(message)
    if message.user?
      render partial: "layouts/user_avatar",      locals: { user: Current.user,           size: 7, classes: "mt-1" }
    else
      render partial: "layouts/assistant_avatar", locals: { assistant: message.assistant, size: 7, classes: "mt-1" }
    end
  end

  def from_name_for(message)
    case message.role
      when "user" then "You"
      when "assistant" then message.assistant.name
      when "tool" then "Tool"
    end
  end

  def format_for_copying(text)
    text
  end

  def format_for_speaking(text)
    ::MarkdownRenderer.render_for_speaking(text)
  end

  def format_for_display(text, append_inside_tag: nil)
    escaped_text = html_escape(text)

    html = ::MarkdownRenderer.render_for_display(
      escaped_text,
      block_code: block_code
    )

    html = "<p></p>" if html.blank?
    html = append(html, append_inside_tag) if append_inside_tag
    return html.html_safe
  end

  private

  def block_code
    ->(code, language) do
      content_tag(:pre,
        class: %|
          p-0
          overflow-x-hidden
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
        div_tag(class: "px-4 py-3 overflow-x-auto") do
          content_tag(:code, code, data: { clipboard_target: "text" })
        end
      end
    end
  end

  def append(html, to_append)
    appended = html.html_safe.sub(/(<\/[^>]+>\n?)\z/, "#{to_append}\\1")

    if appended != html
      appended
    else
      html + to_append
    end
  end
end
