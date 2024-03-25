module MessagesHelper
  def format(text)
    text = html_escape(text)

    if text.include?('`')
      text = paired_single_backticks(text)
      text = paired_triple_backticks(text)
      text = copy_button(text)
    end

    text.html_safe
  end

  def paired_single_backticks(text)
    text.gsub(/(?<!`)(`)(?=[^`]*`)([^`]+)`(?!`)/, '<code><span class="hidden">`</span>\2<span class="hidden">`</span></code>')
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
        ><div class='px-4 py-2 text-xs font-sans bg-gray-600 text-gray-300 flex justify-between items-center clipboard-exclude'
            ><span>#{language}</span
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
        class: "cursor-pointer hover:text-white dark:hover:text-white flex items-center",
        data: {
          role: "clipboard",
          action: %|
            clipboard#copy
            transition#toggleClassOn
            mouseleave->transition#toggleClassOff
          |,
          keyboard_target: "keyboardable",
      }) do
        icon("clipboard", variant: :outline, size: 16, class: "-mt-[1px] tooltip-open", data: { transition_target: "transitionable" }) +
        icon("check", variant: :outline, size: 16, data: { transition_target: "transitionable" }, class: "hidden") +
        "<span class='ml-1'>Copy code</span>".html_safe
      end
    )
  end
end
