module ApplicationHelper
  def icon(name, opts = {})
    opts = opts.symbolize_keys

    variant = opts[:variant]&.to_sym || :solid
    default_size = case variant
      when :outline, :solid
        24
      when :mini
        20
      when :micro
        16
      end

    size = opts[:size] || default_size
    classes = opts[:class] || ""
    raise "Do not include w-# or h-# in the class, use :size instead" if classes.match?(/(\bw-|\bh-)/)
    classes += " w-[#{size}px] h-[#{size}px]"
    title = opts.delete(:title)

    if title
      direction = opts[:tooltip] || 'bottom'

      content_tag(:div, class: classes + " tooltip tooltip-#{direction} hover:tooltip-open", data: { tip: title.to_s }) do
        heroicon name, **opts
      end
    else
      content_tag(:div, class: classes) do
        heroicon name, **opts
      end
    end
  end
end
