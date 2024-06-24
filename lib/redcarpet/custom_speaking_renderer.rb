class Redcarpet::CustomSpeakingRenderer # can't get redcarpet working, just using regex
  def render(markdown)
    not_needing_suffix = %w[javascript jsx typescript css html json markdown yaml]

    markdown.gsub(/```(\w+)?\s*(.*?)```/m) do |match| # paired ````
      if $1.to_s.strip.in? not_needing_suffix
        "Here is some #{$1}."
      else
        "Here is some #{$1.to_s + ($1.present? ? " " : "")}code."
      end
    end.gsub(/```.*$/m, '') # opening ``` without closing`
    .gsub(/\[([^\]]+)\]\(([^)]+)\)/, "Here is a link to \\1") # markdown links
    .gsub(/http[s]?:\/\/[^\s]+/, "this link") # naked links
  end
end
