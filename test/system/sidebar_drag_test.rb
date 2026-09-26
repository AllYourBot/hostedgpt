require "application_system_test_case"

# Only pins carry hand order: the pinned section drags within itself while unpinned rows expose
# no drop targets. The controller test pins what the reorder endpoint does with the ids it
# receives; this test pins what a real drag sends it — a mouse press, a lift past the 6px
# threshold, siblings sliding, a drop, and the order surviving a reload.
class SidebarDragTest < ApplicationSystemTestCase
  test "dragging a pin with the mouse reorders the pinned section and the order persists" do
    user = users(:keith)
    convs = 3.times.map { |i| user.conversations.create!(assistant: assistants(:samantha), title: "DragTarget#{i}") }
    convs.each { |c| c.pin!(user) }
    Conversation.reposition(user, convs.map(&:id)) # normalize pins to 0..2 in creation order

    login_as(user)
    assert_equal ["DragTarget0", "DragTarget1", "DragTarget2"], drag_targets

    drag_row(convs[0], onto: convs[1])
    assert_equal ["DragTarget1", "DragTarget0", "DragTarget2"], drag_targets
    assert_equal [1, 0, 2], convs.map { |c| c.reload.position }

    drag_row(convs[0], onto: convs[2])
    assert_equal ["DragTarget1", "DragTarget2", "DragTarget0"], drag_targets
    assert_equal [2, 0, 1], convs.map { |c| c.reload.position }

    # the dragged row must come back from under the pointer: the dragging class (opacity-0 on the
    # pinned list) has to be removed when the drag ends, or the row vanishes until the next
    # server render replaces it
    assert_true "the dragged row should be visible again after the drop" do
      find("#pinned-conversations [data-sortable-id='#{convs[0].id}']") # find only sees visible elements
      true
    end

    visit root_path # a fresh server render: the dropped order must have been saved, not just slid on screen
    assert_equal ["DragTarget1", "DragTarget2", "DragTarget0"], drag_targets
  end

  test "toggling the pin icon moves the conversation between sections on the next render" do
    user = users(:keith)
    conversation = user.conversations.create!(assistant: assistants(:samantha), title: "PinToggleTarget")

    login_as(user)
    assert pin_row_titles.exclude?("PinToggleTarget")
    assert unpinned_row_titles.include?("PinToggleTarget")

    # Hover first: revealing the row's hover actions shifts the pin button, so a cold click
    # can land beside it and never submit the form.
    pin_row(conversation).hover
    pin_row(conversation).find("[data-role='pin']").click
    assert_true { conversation.reload.pinned?(user) }
    visit root_path

    assert pin_row_titles.include?("PinToggleTarget")

    pin_row(conversation).hover
    pin_row(conversation).find("[data-role='unpin']").click
    assert_true { !conversation.reload.pinned?(user) }
    visit root_path

    assert pin_row_titles.exclude?("PinToggleTarget")
    assert unpinned_row_titles.include?("PinToggleTarget")
  end

  private

  def pin_row(record)
    find("#conversation_#{record.id}")
  end

  def drag_targets
    all("#pinned-conversations [data-role='conversation'] [data-role='title']")
      .map(&:text).grep(/^DragTarget\d/)
  end

  def pin_row_titles
    all("#pinned-conversations [data-role='conversation'] [data-role='title']").map(&:text)
  end

  def unpinned_row_titles
    all("#conversations [data-role='conversation'] [data-role='title']").map(&:text)
  end

  # Press the center of the source row, travel past the mouse-lift threshold, carry it over the
  # center of the target row, and let go. Viewport coordinates throughout — element-origin moves
  # are rejected by headless Chrome's action encoder. The two-step move matters: crossing
  # DragTarget2 in one action can overshoot its midpoint, and a drag past the end of the list
  # commits nothing, so the move is split into "at the top half" then "a row below the midpoint".
  def drag_row(source_record, onto: nil)
    source = find_row(source_record)
    target = find_row(onto)
    source.scroll_to(nil, :center)

    sx, sy = center_of(source)
    target_rect = rect_of(target)
    ty = target_rect[:y] + 4
    ty_height = target_rect[:height]

    page.driver.browser.action
      .move_to_location(sx, sy).click_and_hold
      .move_by(0, 10)
      .move_to_location(sx, ty)
      .pause
      .move_by(0, ty_height / 2)
      .pause
      .release
      .perform
  end

  def rect_of(element)
    page.evaluate_script(
      "(function(el){ var r = el.getBoundingClientRect(); return {x: r.x, y: r.y, width: r.width, height: r.height}; })(arguments[0])",
      element.base.native
    ).then { |h| {x: h["x"], y: h["y"], width: h["width"], height: h["height"]} }
  end

  def find_row(record)
    find("#pinned-conversations [data-sortable-id='#{record.id}']")
  end

  def center_of(element)
    page.evaluate_script(
      "(function(el){ var r = el.getBoundingClientRect(); return [r.x + r.width / 2, r.y + r.height / 2]; })(arguments[0])",
      element.base.native
    ).map(&:to_i)
  end
end
