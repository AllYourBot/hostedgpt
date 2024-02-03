require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 800]

  fixtures :all

  def login_as(user, password = "secret")
    assistant = user.assistants.sorted.first

    visit logout_path
    assert_current_path login_path, wait: 2
    fill_in "email", with: user.person.email
    fill_in "password", with: password
    click_on "Continue"
    assert_current_path new_assistant_message_path(assistant), wait: 2
  end

  def logout
    visit logout_path
    assert_current_path login_path, wait: 2
  end

  def assert_active(selector, error_msg = nil)
    assert_equal find(selector), page.active_element, "Expected #{selector} to be the active element, but it is not. #{error_msg}"
  end

  def assert_selected_assistant(assistant)
    assert_selector "#assistants .relationship", text: assistant.name
  end

  def assert_first_message(message)
    assert_selector "#messages > :first-child .content_text", text: message.content_text
  end

  def assert_visible(selector, error_msg = nil)
    element = find(selector, visible: false) rescue nil
    assert element, "Expected to find visible css #{selector}, but the element was not found. #{error_msg}"
    assert element.visible?, "Expected to find visible css #{selector}. It was found but it is hidden. #{error_msg}"
  end

  def assert_hidden(selector, error_msg = nil)
    element = find(selector, visible: false) rescue nil
    assert element, "Expected to find hidden css #{selector}, but the element was not found. #{error_msg}"
    refute element.visible?, "Expected to find hidden css #{selector}. It was found but it is visible. #{error_msg}"
  end

  def assert_shows_tooltip(selector, text, error_msg = nil)
    assert_selector selector, class: "tooltip"
    assert_equal text, find(selector)[:'data-tip'], "Expected element #{selector} to have tooltip #{text}. #{error_msg}"
  end

  def send_keys(keys)
    element = page.active_element

    key_array = keys.split('+').collect do |key|
      case key
      when 'meta'
        :command
      when 'esc'
        :escape
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
end
