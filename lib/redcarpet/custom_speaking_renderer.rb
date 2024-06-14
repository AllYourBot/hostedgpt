class Redcarpet::CustomSpeakingRenderer # can't get redcarpet working, just using regex
  def render(markdown)
    not_needing_suffix = %w[javascript jsx typescript css html json markdown yaml]

    markdown.gsub(/```(\w+)?\s*(.*?)```/m) do |match|
      if $1.to_s.strip.in? not_needing_suffix
        "Here is some #{$1}."
      else
        "Here is some #{$1.to_s + ($1.present? ? " " : "")}code."
      end
    end.gsub(/```.*$/m, '')
    .gsub(/\[([^\]]+)\]\(([^)]+)\)/, "Here is a link to \\1")
    .gsub(/http[s]?:\/\/[^\s]+/, "this link")
  end
end
