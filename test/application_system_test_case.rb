require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium,
    using: :headless_chrome,
    screen_size: [1400, 800], # this is a short height (800 px) so the viewport scrolls so we can test some scroll interactions
    options: { timeout: 120 }

  fixtures :all

  def login_as(user_or_person, password = "secret")
    user = if user_or_person.is_a?(Person)
      user_or_person.user
    else
      user_or_person
    end

    assistant = user.assistants.ordered.first

    visit logout_path
    assert_current_path login_path
    fill_in "email", with: user.email
    fill_in "password", with: password
    click_text "Log In"
    assert_current_path new_assistant_message_path(assistant)
  end

  def logout
    visit logout_path
    assert_current_path login_path
  end

  def assert_active(selector_or_element, error_msg = nil, wait: Capybara.default_max_wait_time)
    element = if selector_or_element.is_a?(Capybara::Node::Element)
      selector_or_element
    else
      find(selector_or_element, wait: wait)
    end
    assert_true(error_msg || "Expected element to be the active element, but it is not") do
      page.active_element == element
    end
  end

  def assert_visible(selector, error_msg = nil, wait: Capybara.default_max_wait_time)
    elements = all(selector, visible: :all, wait: wait) rescue nil
    assert elements.length == 1, "Ambiguous match, expected to find one visible css #{selector}, but found #{elements.length}. #{error_msg}"
    element = elements.first
    assert element, "Expected to find visible css #{selector}, but the element was not found. #{error_msg}"

    element = find(selector, wait: wait) rescue nil
    assert element, "Expected to find visible css #{selector}. It was found but it is hidden. #{error_msg}"
  end

  def assert_hidden(selector, error_msg = nil, wait: Capybara.default_max_wait_time)
    element = find(selector, visible: :all, wait: wait) rescue nil
    assert element, "Expected to find hidden css #{selector}, but the element was not found. #{error_msg}"
    assert_false "Expected to find hidden css #{selector}. It was found but it is visible. #{error_msg}" do
      element.visible?
    end
  end

  def assert_shows_tooltip(selector_or_element, text, error_msg = nil, wait: Capybara.default_max_wait_time)
    element = if selector_or_element.is_a?(Capybara::Node::Element)
      selector_or_element
    else
      find(selector_or_element, wait: wait)
    end

    unless element.matches_css?(".tooltip", wait: 0) # sometimes we're checking the tooltip on a link but within the link is an icon, check that instead
      element = element.find(:xpath, "./*", match: :first, wait: wait)
    end

    assert element.matches_css?(".tooltip", wait: 0)
    assert_equal text, element[:'data-tip'], "Expected element to have tooltip #{text}. #{error_msg}"
  end

  def send_keys(keys)
    element = page.active_element

    key_array = keys.split("+").collect do |key|
      case key
      when "up"
        :arrow_up
      when "meta"
        :command
      when "esc"
        :escape
      when "backspace"
        :backspace
      when "slash"
        "/"
      when "period"
        "."
      when "enter", "shift"
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

  def click_element(selector_or_element, wait: Capybara.default_max_wait_time)
    element = if selector_or_element.is_a?(Capybara::Node::Element)
      selector_or_element
    else
      find(selector_or_element, wait: wait)
    end

    element.click
  end

  def get_scroll_position(selector)
    page.evaluate_script("document.querySelector('#{selector}').scrollTop + document.querySelector('#{selector}').clientHeight").to_i
  end

  def get_bottom_position(selector)
    page.evaluate_script("document.querySelector('#{selector}').scrollHeight").to_i
  end

  def scroll_to_bottom(selector)
    page.execute_script("document.querySelector('#{selector}').scrollTop = document.querySelector('#{selector}').scrollHeight")
  end

  def scroll_to_position(selector, position)
    page.execute_script("document.querySelector('#{selector}').scrollTop = #{position}")
  end

  def assert_did_not_scroll(selector = "section #messages-container")
    raise "No block given" unless block_given?

    scroll_position_first_element_relative_viewport = nil

    assert_true "The #{selector} should have stopped scrolling before it could begin" do
      scroll_position_first_element_relative_viewport = page.evaluate_script("document.querySelector('#{selector}').children[1].getBoundingClientRect().top")
      sleep 0.5
      scroll_position_first_element_relative_viewport == page.evaluate_script("document.querySelector('#{selector}').children[1].getBoundingClientRect().top")
    end

    yield

    new_scroll = nil
    assert_true "The #{selector} should not have scrolled but position changed from #{scroll_position_first_element_relative_viewport}" do
      new_scroll = page.evaluate_script("document.querySelector('#{selector}').children[1].getBoundingClientRect().top")
      scroll_position_first_element_relative_viewport == new_scroll
    end
  end

  def assert_scrolled_up(selector = "section #messages")
    raise "No block given" unless block_given?

    scroll_position = get_scroll_position(selector)

    yield

    assert_true "The #{selector} should have scrolled up" do
      get_scroll_position(selector) < scroll_position
    end

    assert_stopped_scrolling(selector)
  end

  def assert_scrolled_down(selector = "section #messages")
    raise "No block given" unless block_given?

    scroll_position = get_scroll_position(selector)

    yield

    assert_true "The #{selector} should have scrolled down" do
      get_scroll_position(selector) > scroll_position
    end

    assert_stopped_scrolling(selector)
  end

  def assert_stopped_scrolling(selector = "section #messages")
    assert_true "The #{selector} should have stopped scrolling" do
      prev_scroll_position = get_scroll_position(selector)
      sleep 0.5
      get_scroll_position(selector) == prev_scroll_position
    end
  end

  def assert_at_bottom(selector = "section #messages")
    assert_stopped_scrolling(selector)
    assert_equal get_bottom_position(selector), get_scroll_position(selector), "The #{selector} was able to move down so it was not at the bottom"
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
    assert_stopped_scrolling(selector)
    assert_at_bottom(selector)
  end

  def resize_browser_to(width, height)
    page.driver.browser.manage.window.resize_to(width, height)
  end

  def find_messages
    all("#conversation [data-role='message']").to_a
  end

  def last_message
    find_messages.last
  end

  def last_user_message
    find_messages.last(2).first
  end

  def first_message
    find_messages.first
  end

  def clipboard
    page.evaluate_script("window.clipboardForSystemTestsToCheck")
  end

  def assert_true(msg = nil, opts = {}, &block)
    timeout = opts[:wait] || Capybara.default_max_wait_time
    prev_default_wait = Capybara.default_max_wait_time

    Capybara.default_max_wait_time = 0
    Timeout.timeout(timeout) do
      sleep 0.25 until block.call
    end
  rescue Timeout::Error
    assert false, msg || "Expected block to return true, but it did not"
  ensure
    Capybara.default_max_wait_time = prev_default_wait
  end

  def assert_false(msg = nil, opts = {}, &block)
    timeout = opts[:wait] || Capybara.default_max_wait_time
    prev_default_wait = Capybara.default_max_wait_time

    Capybara.default_max_wait_time = 0
    Timeout.timeout(timeout) do
      sleep 0.25 until !block.call
    end
  rescue Timeout::Error
    refute true, msg || "Expected block to return false, but it did not"
  ensure
    Capybara.default_max_wait_time = prev_default_wait
  end

  def wait_for_images_to_load
    assert_false "all the image loaders should have disappeared" do
      all("[data-role='image-loader']", visible: :all).map(&:visible?).include?(true)
    end

    assert_false "all values in the loading object should have been 'loaded'" do
      page.evaluate_script("Object.values(window.imageLoadingForSystemTestsToCheck).filter((v) => v != 'done').length > 0")
    end
  end

  def wait_for_initial_scroll_down
    assert_true "waiting for scroll down after initial page load" do
      page.evaluate_script("window.scrolledDownForSystemTestsToCheck")
    end
  end

  def assert_composer_blank(msg = nil)
    msg ||= "Composer input did not clear"
    assert_true msg do
      composer.value.blank?
    end
  end

  def composer
    find(composer_selector)
  end

  def composer_selector
    "#composer textarea"
  end

  def hover_last_message
    msg = last_message
    msg.hover
    msg
  end

  def assert_selected_assistant(assistant)
    assert_selector "#assistants .relationship", text: assistant.name
  end

  def assert_first_message(message)
    assert_selector "#messages > :first-child [data-role='content-text']", text: message.content_text
  end

  def assert_last_message(message)
    assert_selector "#messages > :last-child [data-role='content-text']", text: message.content_text
  end

  def assert_alert(text)
    alert = nil
    assert_true "the alert element could not be found" do
      alert = find("#alerts .alert > span", visible: :all, wait: 0) rescue nil
    end
    assert_equal text, alert[:innerText]
  end

  def visit_and_scroll_wait(path, debug: false)
    visit path

    path_without_query = URI.parse(path).path # ignore_query only ignores it from the current_path so strip ourselves
    assert_current_path path_without_query, ignore_query: true

    wait_for_initial_scroll_down
  end
end

class Capybara::Node::Element
  def find_role(label)
    find("[data-role='#{label}']", visible: :all)
  end

  def find_target(label, controller:)
    find("[data-#{controller}-target='#{label}']", visible: :all)
  end
end
