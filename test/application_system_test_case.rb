require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium,
    using: :headless_chrome,
    screen_size: [1400, 800]  # this is a short height (800 px) so the viewport scrolls so we can test some scroll interactions

  fixtures :all

  def login_as(user_or_person, password = "secret")
    user = if user_or_person.is_a?(Person)
      user_or_person.user
    else
      user_or_person
    end

    assistant = user.assistants.ordered.first

    visit logout_path
    assert_current_path login_path, wait: 2
    fill_in "email", with: user.person.email
    fill_in "password", with: password
    click_text "Log In"
    assert_current_path new_assistant_message_path(assistant), wait: 2
  end

  def logout
    visit logout_path
    assert_current_path login_path, wait: 2
  end

  def assert_active(selector_or_element, error_msg = nil, wait: nil)
    element = if selector_or_element.is_a?(Capybara::Node::Element)
      selector_or_element
    else
      find(selector_or_element, wait: wait)
    end
    assert_equal element, page.active_element, error_msg || "Expected element to be the active element, but it is not"
  end

  def assert_visible(selector, error_msg = nil, wait: 0)
    element = first(selector, visible: false, wait: wait) rescue nil
    assert element, "Expected to find visible css #{selector}, but the element was not found. #{error_msg}"

    element = first(selector, visible: true, wait: wait) rescue nil

    unless element&.visible?
      sleep wait
      element = find(selector, visible: true, wait: wait) rescue nil
    end

    assert element&.visible?, "Expected to find visible css #{selector}. It was found but it is hidden. #{error_msg}"
  end

  def assert_hidden(selector, error_msg = nil, wait: nil)
    element = find(selector, visible: false, wait: wait) rescue nil
    assert element, "Expected to find hidden css #{selector}, but the element was not found. #{error_msg}"
    sleep wait  if wait.present?  # we can wait until an element is visible, but if we want to be sure it's disappearing we need to sleep
    refute element.visible?, "Expected to find hidden css #{selector}. It was found but it is visible. #{error_msg}"
  end

  def assert_shows_tooltip(selector_or_element, text, error_msg = nil, wait: nil)
    element = if selector_or_element.is_a?(Capybara::Node::Element)
      selector_or_element
    else
      find(selector_or_element, wait: wait)
    end

    unless element.matches_css?(".tooltip") # sometimes we're checking the tooltip on a link but within the link is an icon, check that instead
      element = element.find(:xpath, './*', match: :first, wait: wait)
    end

    assert element.matches_css?(".tooltip")
    assert_equal text, element[:'data-tip'], "Expected element to have tooltip #{text}. #{error_msg}"
  end

  def send_keys(keys)
    element = page.active_element

    key_array = keys.split('+').collect do |key|
      case key
      when 'meta'
        :command
      when 'esc'
        :escape
      when 'backspace'
        :backspace
      when 'slash'
        '/'
      when 'period'
        '.'
      when 'enter', 'shift'
        key.to_sym
      else
        key
      end
    end

    element.send_keys key_array
  end

  def click_text(text, params = {})
    click_on text, **params
  end

  def click_element(selector_or_element, wait: nil)
    element = if selector_or_element.is_a?(Capybara::Node::Element)
      selector_or_element
    else
      find(selector_or_element, wait: wait)
    end

    element.click
  end

  def get_scroll_position(selector)
    page.evaluate_script("document.querySelector('#{selector}').scrollTop")
  end

  def scroll_to_bottom(selector)
    page.execute_script("document.querySelector('#{selector}').scrollTop = document.querySelector('#{selector}').scrollHeight")
  end

  def assert_did_not_scroll(selector = "section #messages")
    raise "No block given" unless block_given?

    scroll_position_first_element_relative_viewport = page.evaluate_script("document.querySelector('#{selector}').firstElementChild.getBoundingClientRect().top")
    yield
    new_scroll_position_first_element_relative_viewport = page.evaluate_script("document.querySelector('#{selector}').firstElementChild.getBoundingClientRect().top")

    assert_equal scroll_position_first_element_relative_viewport,
      new_scroll_position_first_element_relative_viewport,
      "The #{selector} should not have scrolled"
  end

  def assert_scrolled_up(selector = "section #messages")
    raise "No block given" unless block_given?

    scroll_position = get_scroll_position(selector)
    yield
    assert get_scroll_position(selector) > scroll_position, "The #{selector} should have scrolled up"
  end

  def assert_scrolled_down(selector = "section #messages")
    raise "No block given" unless block_given?

    scroll_position = get_scroll_position(selector)
    yield
    assert get_scroll_position(selector) > scroll_position, "The #{selector} should have scrolled down"
  end

  def assert_at_bottom(selector = "section #messages")
    sleep 0.1
    new_scroll_position = get_scroll_position(selector)
    scroll_to_bottom(selector)
    assert_equal new_scroll_position, get_scroll_position(selector), "The #{selector} did not scroll to the bottom."
  end

  def assert_scrolled_to_bottom(selector = "section #messages")
    raise "No block given" unless block_given?

    assert_scrolled_down(selector) do
      yield
    end

    assert_at_bottom(selector)
  end

  def assert_stays_at_bottom(selector = "section #messages")
    raise "No block given" unless block_given?

    assert_at_bottom(selector)
    yield
    assert_at_bottom(selector)
  end

  def resize_browser_to(width, height)
    page.driver.browser.manage.window.resize_to(width, height)
  end

  def find_messages
    all("#conversation [data-role='message']").to_a
  end
end
