module MorphingHelper
  private

  def assert_page_morphed
    raise "No block given" unless block_given?
    watch_page_for_morphing

    yield

    sleep 1 # this delay is so long b/c we wait 0.5s before scrolling the page down
    assert get_scroll_position("section #messages") > @messages_scroll_position, "The page should have scrolled down further"
    assert_hidden "#scroll-button", "The page did not scroll all the way down"
    assert tagged?("nav"), "The page did not morph; a tagged element got replaced."
    assert tagged?(first_message), "The page did not morph; a tagged element got replaced."
    assert_equal @nav_scroll_position, get_scroll_position("nav"), "The left column lost it's scroll position"
  end

  def watch_page_for_morphing
    # Within automated system tests, it's difficult to know if a page morphed or not. When a page does morph
    # it should only replace the DOM elements which changed. This has the side effect of preserving scroll position.
    # However, full page Turbo transitions also have other hacks in place to preserve scroll position so that
    # is not enough. The best solution I found was to test for the scroll position *and* to test if a couple
    # elements we expect NOT to be replaced stay put. The way I test this is by "tagging" an element; this adds an
    # attribute to the element which morphdom ignores so it does not recognize this as a changed element. A full
    # page body replacement or a turbo-frame replacement does not re-add these attributes, so if the tag is no longer
    # present then we know morphing did not occur.
    tag("nav")
    tag(first_message)
    @nav_scroll_position = get_scroll_position("nav")
    sleep 1 # this delay is so long b/c we wait 0.5s before scrolling the page down
    @messages_scroll_position = get_scroll_position("section #messages")
    assert_not_equal 0, @messages_scroll_position, "The page should be scrolled down before acting on it"
  end

  def tag(selector_or_element)
    element = if selector_or_element.is_a?(Capybara::Node::Element)
      selector_or_element
    else
      find(selector_or_element)
    end

    page.execute_script("arguments[0]._morphMonitor = true", element)
  end

  def tagged?(selector_or_element)
    element = if selector_or_element.is_a?(Capybara::Node::Element)
      selector_or_element
    else
      find(selector_or_element)
    end

    element[:'_morphMonitor']
  end
end
