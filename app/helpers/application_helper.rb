module ApplicationHelper
  def icon(name, opts = {})
    opts = opts.deep_symbolize_keys

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
    classes += " icon block "
    raise "Do not include w-# or h-# in the class, use :size instead" if classes.match?(/(\bw-|\bh-)/)
    title = opts.delete(:title)

    if title
      direction = opts.delete(:tooltip) || 'bottom'
      data = opts.delete(:data) || {}

      content_tag(:div,
        class: classes + " tooltip tooltip-#{direction} hover:tooltip-open",
        style: "width: #{size}px; height: #{size}px;",
        data: { tip: title.to_s }.merge(data),
        **opts.except(:class, :size, :variant)
      ) do
        heroicon name, **opts.slice(:size, :variant)
      end
    else
      content_tag(:div,
        class: classes,
        style: "width: #{size}px; height: #{size}px;",
        **opts.except(:class, :size, :variant)
      ) do
        heroicon name, **opts
      end
    end
  end

  def flash_tag(type, text)
    alert_class = case type
      when "alert"
        "error"
      else
        "info"
      end
    tag.div class: "alert alert-#{alert_class}" do
      tag.span text
    end
  end

  def span_tag(content_or_options_with_block = nil, options = nil, &block)
    if block_given?
      options = content_or_options_with_block if content_or_options_with_block.is_a?(Hash)
      content_tag(:span, options, &block)
    else
      content_tag(:span, content_or_options_with_block, options)
    end
  end

  def div_tag(content_or_options_with_block = nil, options = nil, &block)
    if block_given?
      options = content_or_options_with_block if content_or_options_with_block.is_a?(Hash)
      content_tag(:div, options, &block)
    else
      content_tag(:div, content_or_options_with_block, options)
    end
  end
end
