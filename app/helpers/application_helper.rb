module ApplicationHelper

  def at_most_two_initials(initials)
    return initials if initials.nil? || initials.length <= 2
    initials[0] + initials[-1]
  end

  def spinner(opts = {})
    html = <<~HTML
      <svg class="animate-spin -ml-1 mr-3 h-#{opts[:size]} w-#{opts[:size]} #{opts[:class]}" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
    HTML
    html.html_safe
  end

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
      direction = opts.delete(:tooltip) || "bottom"
      data = opts.delete(:data) || {}

      content_tag(:span,
        class: classes + " tooltip tooltip-#{direction} hover:tooltip-open",
        style: "width: #{size}px; height: #{size}px;",
        data: { tip: title.to_s }.merge(data),
        **opts.except(:class, :size, :variant, :svg)
      ) do
        heroicon name, **opts.slice(:size, :variant).merge(opts[:svg] || {})
      end
    else
      content_tag(:span,
        class: classes,
        style: "width: #{size}px; height: #{size}px;",
        **opts.except(:class, :size, :variant, :svg)
      ) do
        heroicon name, **opts.merge(opts[:svg] || {})
      end
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

  def meta_tag(name, content)
    tag.meta(name:, content:)
  end

  def charset_tag(charset)
    tag.meta(charset:)
  end

  def viewport_tag(content)
    tag.meta(name: "viewport", content:)
  end

  def n_a_if_blank(value, n_a = I18n.t("app.helpers.application.not_available"))
    value.blank? ? n_a : value.to_s
  end

  def to_dollars(cents, precision: 2)
    number_to_currency(cents / 100.0, precision:)
  end
end
