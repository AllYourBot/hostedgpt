module ConversationsHelper
  def gpt(title)
    content_tag(:div, class: "h-9 flex flex-1 mr-6 my-1 rounded-lg hover:bg-zinc-400 hover:bg-opacity-20") do
      content_tag(:div, class: "flex-1 flex flex-row mx-3 my-1") do
        content_tag(:div, "", class: "w-7 bg-white rounded-full") +
          content_tag(:div, title, class: "flex-1 flex items-center ml-2 text-white text-sm")
      end
    end
  end

  def conversation(title)
    content_tag(:div, class: "h-9 flex mr-6 rounded-lg hover:bg-zinc-400 hover:bg-opacity-20") do
      content_tag(:div, class: "flex-1 flex mx-1 my-1") do
        content_tag(:div, title, class: "flex-1 flex items-center ml-2 text-white text-sm text-opacity-80")
      end
    end
  end
end
