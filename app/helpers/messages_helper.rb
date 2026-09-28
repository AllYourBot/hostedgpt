require "./lib/markdown_renderer"

module MessagesHelper
  # Every model can take a PDF (as extracted text if nothing else), but only some can see images.
  def attachment_types_for(assistant)
    assistant.supports_images? ? "image/*,.pdf" : ".pdf"
  end

  def render_avatar_for(message)
    if message.user?
      render partial: "layouts/user_avatar",      locals: { user: Current.user,           size: 7, classes: "mt-1" }
    elsif message.tool?
      render partial: "layouts/tool_avatar"
    else
      render partial: "layouts/assistant_avatar", locals: { assistant: message.assistant, size: 7, classes: "mt-1" }
    end
  end

  def from_name_for(message)
    case message.role
  when "user" then I18n.t("app.helpers.messages.from_user")
      when "assistant" then message.assistant.name
      end
  end

  def format_for_copying(text)
    text
  end

  def format_for_speaking(text)
    ::MarkdownRenderer.render_for_speaking(text)
  end

  def format_for_display(message, append_inside_tag: nil)
    parsed_tool_result = message_to_user_hash(message)
    if parsed_tool_result
      function_name = message.content_tool_calls.dig(:function, :name)
      message_to_user = parsed_tool_result["message_to_user"]

      # Tools own their deep links: the tool result carries the URL itself.
      # Only https URLs render; the sink is guarded because future tools may
      # carry externally influenced URLs and link_to does not filter schemes.
      if (link_url = safe_tool_link_url(parsed_tool_result["link_url"]))
        return tool_result_link_to(message_to_user, link_url)
      end

      # The two search cases below are legacy fallbacks for rows persisted
      # before tools carried link_url. The memory case is permanent: it links
      # to an internal page no tool result carries.
      case function_name
      when "memory_remember_detail_about_user"
        return link_to message_to_user,
        settings_memories_path,
        { data: { turbo_frame: "_top" }, class: "text-gray-400 dark:!text-gray-500 font-normal no-underline" }
      when *LEGACY_SEARCH_TOOL_NAMES
        return tool_result_link_to(message_to_user, legacy_search_url(function_name, message_to_user))
      else
        return content_tag(:span, message_to_user, class: "text-gray-400 dark:!text-gray-500")
      end
    else
      escaped_text = html_escape(message.content_text)

      html = ::MarkdownRenderer.render_for_display(
        escaped_text,
        block_code: block_code
      )

      html = "<p></p>" if html.blank?
      html = append(html, append_inside_tag) if append_inside_tag
      return html.html_safe
    end
  end

  def thinking_html(message, thinking)
    span_tag("", data: { role: "thinking", stream_watchdog_target: "thinking" }, class: %|
      animate-breathe
      w-3 h-3
      rounded-full
      bg-black dark:bg-white
      inline-block
      ml-1
      #{!thinking && 'hidden'}
    |) +
    span_tag(" ...", class: (message.content_text.blank? || message.not_cancelled?) && "hidden") +
    icon("stop",
      variant: :solid,
      size: 17,
      title: I18n.t("app.helpers.messages.stopped"),
      tooltip: :top,
      data: { role: "cancelled" },
      class: "inline-block pl-1 #{message.not_cancelled? && 'hidden'}"
    )
  end

  def message_to_user_from_tool_call?(message)
    message_to_user_hash(message).present?
  end

  private

  # Rows persisted before tools carried link_url still render as links, built
  # exactly as they always were.
  LEGACY_SEARCH_TOOL_NAMES = %w[googlesearch_google_search bravesearch_brave_search].freeze

  def legacy_search_url(function_name, message_to_user)
    query = message_to_user.partition(":").last
    return Toolbox::BraveSearch.search_url(query) if function_name == "bravesearch_brave_search"

    "https://www.google.com/search?q=#{URI.encode_www_form_component(query)}"
  end

  def message_to_user_hash(message)
    @message_to_user_hashes ||= {}
    @message_to_user_hashes[message.content_text] ||= begin
      return nil if message.content_text.blank?
      hash = JSON.parse(message.content_text)
      hash.is_a?(Hash) && hash["message_to_user"].present? ? hash : nil
    rescue JSON::ParserError
      nil
    end
  end

  # Tool-result deep links are https-only. Anything else (javascript:, data:,
  # malformed) falls back to plain text rather than rendering as an anchor.
  def safe_tool_link_url(url)
    url.to_s.start_with?("https://") && url
  end

  def tool_result_link_to(text, url)
    link_to text, url, target: :_blank, data: { turbo_frame: "_top" }, class: "text-gray-400 dark:!text-gray-500 font-normal no-underline"
  end

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
            span_tag(I18n.t("app.helpers.messages.copy_code"), data: { transition_target: "transitionable" }, class: "ml-1") +
            icon("check",     variant: :outline, size: 16, data: { transition_target: "transitionable" }, class: "hidden") +
            span_tag(I18n.t("app.helpers.messages.copied"), data: { transition_target: "transitionable" }, class: "hidden ml-1")
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
