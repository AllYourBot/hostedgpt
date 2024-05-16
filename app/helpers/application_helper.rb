module ApplicationHelper

  def hide_assistant_class(item, item_counter)
    return nil unless item.is_a?(Assistant)
    return 'hidden' if @hide_settings_assistants_overflow && item_counter >= Assistant::MAX_LIST_DISPLAY
    nil
  end

  def assitant_data_transaction_target(item, item_counter)
    return nil unless item.is_a?(Assistant)
    return 'data-transition-target="transitionable"'.html_safe if @hide_settings_assistants_overflow && item_counter >= Assistant::MAX_LIST_DISPLAY
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
      direction = opts.delete(:tooltip) || 'bottom'
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

  def meta_tag(name, content)
    tag.meta(name: name, content: content)
  end

  def charset_tag(charset)
    tag.meta(charset: charset)
  end

  def viewport_tag(content)
    tag.meta(name: 'viewport', content: content)
  end

end
