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
    click_on "Log In"
    assert_current_path new_assistant_message_path(assistant), wait: 2
  end

  def logout
    visit logout_path
    assert_current_path login_path, wait: 2
  end

  def assert_active(selector, error_msg = nil, wait: nil)
    element = find(selector, wait: wait)
    assert_equal element, page.active_element, "Expected #{selector} to be the active element, but it is not. #{error_msg}"
  end

  def assert_visible(selector, error_msg = nil, wait: nil)
    element = find(selector, visible: false, wait: wait) rescue nil
    assert element, "Expected to find visible css #{selector}, but the element was not found. #{error_msg}"

    element = find(selector, visible: true, wait: wait) rescue nil
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
    page.evaluate_script("arguments[0].scrollTop", find(selector))
  end
end
