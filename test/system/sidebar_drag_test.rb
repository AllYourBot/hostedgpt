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

  # Touch path: a still finger hold lifts the row where an early move would scroll
  # instead. Driven through CDP touch input (no mobile emulation needed — desktop
  # layout, touch pointer events), asserting the same commit + persistence contract.
  test "a still touch hold drag reorders pins and the order persists" do
    user = users(:keith)
    convs = 3.times.map { |i| user.conversations.create!(assistant: assistants(:samantha), title: "DragTouch#{i}") }
    convs.each { |c| c.pin!(user) }
    Conversation.reposition(user, convs.map(&:id)) # normalize pins to 0..2 in creation order

    login_as(user)
    visit root_path
    assert_equal ["DragTouch0", "DragTouch1", "DragTouch2"], drag_touch_targets

    touch_drag_row(convs[0], onto: convs[1])
    assert_equal ["DragTouch1", "DragTouch0", "DragTouch2"], drag_touch_targets
    assert_equal [1, 0, 2], convs.map { |c| c.reload.position }

    visit root_path # a fresh server render: the dropped order must have been saved, not just slid on screen
    assert_equal ["DragTouch1", "DragTouch0", "DragTouch2"], drag_touch_targets
  end

  # Picker-row contract: the sidebar picker lives inside the draggable row, and the sortable
  # ghost clone strips Stimulus wiring from its scenery copy only — so the row's own picker
  # controller stays connected through a committing drag, with counts intact and still usable.
  test "dragging a pinned row with its picker open commits the drop and the picker still works" do
    user = users(:keith)
    convs = 3.times.map { |i| user.conversations.create!(assistant: assistants(:samantha), title: "DragPicker#{i}") }
    convs.each { |c| c.pin!(user) }
    Conversation.reposition(user, convs.map(&:id)) # normalize pins to 0..2 in creation order
    convs[0].react!("🎉", user)

    login_as(user)
    visit root_path
    assert_equal ["DragPicker0", "DragPicker1", "DragPicker2"], drag_picker_targets

    row = find("#conversation_#{convs[0].id}")
    assert_includes row.find("[data-role='reaction-counts']").text, "🎉 1"

    row.find("[data-role='react-conversation']").click
    within("#conversation_#{convs[0].id}") do
      assert_selector("[data-emoji-picker-target='panel']")
    end

    # Grab the title: the open panel floats above the row's right end, where a center grab
    # would land on the panel (a button — drags never arm from buttons) instead of the row.
    drag_row_by_title(convs[0], onto: convs[1])
    assert_true { drag_picker_targets == ["DragPicker1", "DragPicker0", "DragPicker2"] }
    assert_equal [1, 0, 2], convs.map { |c| c.reload.position }

    # Counts survive the committing drag, and the row's own picker controller is still wired.
    moved = find("#conversation_#{convs[0].id}")
    within("#conversation_#{convs[0].id}") do
      assert_selector("[data-role='reaction-counts']", text: "🎉 1")
    end

    moved.find("[data-role='react-conversation']").click
    within("#conversation_#{convs[0].id}") do
      assert_selector("[data-emoji-picker-target='panel']")
    end

    moved.find("[data-role='react-emoji-conversation']", text: "❤️").click
    assert_true "the sidebar chip should render after the drag" do
      find("#conversation_#{convs[0].id}").find("[data-role='reaction-counts']").text.include?("❤️ 1")
    end
    assert_true "the reaction should persist" do
      convs[0].reload.user_reacted?("❤️", user)
    end

    visit root_path # a fresh server render: the dropped order must have been saved, not just slid on screen
    assert_equal ["DragPicker1", "DragPicker0", "DragPicker2"], drag_picker_targets
  end

  # Edge: picker open during a cross-zone drop — the row changes membership and both lists
  # re-render, and the picker on the moved row must still work.
  test "picker open during a cross-zone drop still unpins and keeps working" do
    user = users(:keith)
    pinned = user.conversations.create!(assistant: assistants(:samantha), title: "ZonePickerPinned")
    user.conversations.create!(assistant: assistants(:samantha), title: "ZonePickerPlain")
    pinned.pin!(user)
    pinned.react!("🎉", user)

    login_as(user)
    visit root_path

    row = find("#conversation_#{pinned.id}")
    assert_includes row.find("[data-role='reaction-counts']").text, "🎉 1"
    row.find("[data-role='react-conversation']").click
    assert row.find("[data-emoji-picker-target='panel']").visible?

    # Title grab again: the open panel would swallow a center press (see above).
    drag_boundary(pinned, zone: "unpinned", grab: :title)
    assert_true { !pinned.reload.pinned?(user) }
    assert_selector("#conversations [data-sortable-id='#{pinned.id}']")

    moved = find("#conversation_#{pinned.id}")
    within("#conversation_#{pinned.id}") do
      assert_selector("[data-role='reaction-counts']", text: "🎉 1")
    end
    moved.find("[data-role='react-conversation']").click
    within("#conversation_#{pinned.id}") do
      assert_selector("[data-emoji-picker-target='panel']")
    end
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
    assert_selector("#conversation_#{conversation.id} [data-role='unpin']")
    visit root_path

    assert pin_row_titles.include?("PinToggleTarget")

    pin_row(conversation).hover
    pin_row(conversation).find("[data-role='unpin']").click
    assert_true { !conversation.reload.pinned?(user) }
    assert_selector("#conversation_#{conversation.id} [data-role='pin']")
    visit root_path

    assert pin_row_titles.exclude?("PinToggleTarget")
    assert unpinned_row_titles.include?("PinToggleTarget")
  end

  test "pinning the first chat retires the date groups for Recent, unpinning restores them" do
    user = users(:keith)
    conversation = user.conversations.create!(assistant: assistants(:samantha), title: "GroupRetireTarget")

    login_as(user)
    visit root_path
    assert_selector("[data-role='time-group']")
    assert_no_selector("[data-role='recent-header']")

    pin_row(conversation).hover
    pin_row(conversation).find("[data-role='pin']").click
    assert_selector("#conversation_#{conversation.id} [data-role='unpin']")
    assert_selector("[data-role='recent-header']", text: "Recent")
    assert_no_selector("[data-role='time-group']")

    pin_row(conversation).hover
    pin_row(conversation).find("[data-role='unpin']").click
    assert_selector("#conversation_#{conversation.id} [data-role='pin']")
    assert_selector("[data-role='time-group']")
    assert_no_selector("[data-role='recent-header']")
  end

  test "dragging across sections pins and unpins" do
    user = users(:keith)
    pinned = user.conversations.create!(assistant: assistants(:samantha), title: "ZonePinned")
    user.conversations.create!(assistant: assistants(:samantha), title: "ZonePlain")
    pinned.pin!(user)

    login_as(user)
    visit root_path

    assert pin_row_titles.include?("ZonePinned")

    # Drag the top unpinned row up into the pinned area: it pins and persists.
    candidate_id = settled_row_id("#conversations", :first)
    candidate = Conversation.find(candidate_id)
    drag_boundary(candidate, zone: "pinned")
    assert_true { candidate.reload.pinned?(user) }
    assert_selector("#pinned-conversations [data-sortable-id='#{candidate.id}']")

    # Drag the bottom pinned row down out of the pinned area: it unpins and persists.
    bottom_pin_id = settled_row_id("#pinned-conversations", :last)
    bottom_pin = Conversation.find(bottom_pin_id)
    drag_boundary(bottom_pin, zone: "unpinned")
    assert_true { !bottom_pin.reload.pinned?(user) }

    visit root_path
    assert pin_row_titles.exclude?(bottom_pin.title)
    assert unpinned_row_titles.include?(bottom_pin.title)
  end

  private

  def pin_row(record)
    find("#conversation_#{record.id}")
  end

  def drag_targets
    all("#pinned-conversations [data-role='conversation'] [data-role='title']")
      .map(&:text).grep(/^DragTarget\d/)
  end

  def drag_touch_targets
    all("#pinned-conversations [data-role='conversation'] [data-role='title']")
      .map(&:text).grep(/^DragTouch\d/)
  end

  # Title-quarter grab shared by the finger and mouse title drags: the open picker
  # panel covers the row's right end, so both press left-of-center where only the
  # title link (which intentionally still arms) sits.
  def title_grab_point(record)
    rect = rect_of(find_row(record))
    [(rect[:x] + rect[:width] / 4).to_i, (rect[:y] + rect[:height] / 2).to_i]
  end

  # Finger drag through CDP touch input: press and hold still past the controller's
  # still-hold threshold (an early move reads as scroll and cancels), then travel in
  # small steps to the target's bottom half and release. Coordinates are viewport
  # integers; the touch id stays constant across the gesture.
  def touch_drag_row(source_record, onto: nil)
    target = find_row(onto)
    scroll_row_into_view(source_record)

    sx, sy = title_grab_point(source_record)
    target_rect = rect_of(target)
    ty = (target_rect[:y] + target_rect[:height] * 0.75).to_i

    perform_drop do
      touch(:touchStart, x: sx, y: sy)
      sleep 0.4
      steps = 4
      steps.times do |i|
        y = sy + ((ty - sy) * (i + 1) / steps)
        touch(:touchMove, x: sx, y: y)
        sleep 0.05
      end
      touch(:touchEnd)
    end
  end

  def touch(type, x: nil, y: nil)
    points = (type == :touchEnd) ? [] : [{ x: x.to_i, y: y.to_i, id: 1 }]
    page.driver.browser.execute_cdp("Input.dispatchTouchEvent", type: type.to_s, touchPoints: points)
  end

  def drag_picker_targets
    all("#pinned-conversations [data-role='conversation'] [data-role='title']")
      .map(&:text).grep(/^DragPicker\d/)
  end
  def pin_row_titles
    all("#pinned-conversations [data-role='conversation'] [data-role='title']").map(&:text)
  end

  def unpinned_row_titles
    all("#conversations [data-role='conversation'] [data-role='title']").map(&:text)
  end

  # Settles a drop deterministically: the controller flips this flag once the commit
  # path runs to completion, so DB asserts wait on done instead of racing the commit
  # fetch against a fixed timeout (a loaded box once stretched the unpin round trip
  # past the wait window with the row slid but uncommitted). Reset before acting so a
  # press that never lifts cannot pass on a previous drag's flag.
  def perform_drop(&action)
    page.evaluate_script("window.dropSettledForSystemTestsToCheck = false")
    action.call
    assert_true "the drop should settle its commit path" do
      page.evaluate_script("window.dropSettledForSystemTestsToCheck") == true
    end
  end

  # Reads a row id off a list that a stream re-render may be replacing: attribute reads
  # on a node detached mid-render come back nil, so wait for a present value.
  def settled_row_id(frame_selector, position)
    row_id = nil
    assert_true "a row id should be readable in #{frame_selector}" do
      row_id = all("#{frame_selector} [data-sortable-id]").public_send(position)&.[]("data-sortable-id")
      row_id.present?
    end
    row_id
  end

  # Press the center of the source row, travel past the mouse-lift threshold, carry it over the
  # center of the target row, and let go. Viewport coordinates throughout — element-origin moves
  # are rejected by headless Chrome's action encoder. The two-step move matters: crossing
  # DragTarget2 in one action can overshoot its midpoint, and a drag past the end of the list
  # commits nothing, so the move is split into "at the top half" then "a row below the midpoint".
  def drag_row(source_record, onto: nil)
    source = find_row(source_record)
    target = find_row(onto)
    scroll_row_into_view(source_record)

    sx, sy = center_of(source)
    target_rect = rect_of(target)
    ty = target_rect[:y] + 4
    ty_height = target_rect[:height]

    perform_drop do
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
  end

  def rect_of(element)
    page.evaluate_script(
      "(function(el){ var r = el.getBoundingClientRect(); return {x: r.x, y: r.y, width: r.width, height: r.height}; })(arguments[0])",
      element.base.native
    ).then { |h| {x: h["x"], y: h["y"], width: h["width"], height: h["height"]} }
  end

  # Same real-mouse drag as drag_row, but pressing the title (left quarter) instead of the
  # row center: with a picker panel open over the row's right end, a center grab lands on the
  # panel — a button, which never arms a drag — while the title intentionally still arms.
  def drag_row_by_title(source_record, onto: nil)
    target = find_row(onto)
    scroll_row_into_view(source_record)

    sx, sy = title_grab_point(source_record)
    target_rect = rect_of(target)
    ty = target_rect[:y] + 4
    ty_height = target_rect[:height]

    perform_drop do
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
  end

  def find_row(record)
    find("#pinned-conversations [data-sortable-id='#{record.id}']")
  end

  # Real scrollIntoView, measured after: Capybara's scroll_to is a no-op in this
  # setup, so stale document coords used to send drops onto the footer under the
  # list — zoneless, silently restored, never committed. The funnel section added
  # enough sidebar height to push the third pinned row below the fold and expose it.
  def scroll_row_into_view(record)
    page.execute_script(
      "(function(){ document.querySelector('#nav-conversations [data-sortable-id=\"RID\"]'.replace('RID', '#{record.id}')).scrollIntoView({block: 'center'}); })()"
    )
  end

  # Any draggable row in the main-view sidebar, pinned or unpinned: cross-zone drops read the
  # drop position, so the finder cannot assume a section.
  def find_any_row(record)
    find("#nav-conversations [data-sortable-id='#{record.id}']")
  end

  # Short cross-boundary drags in one action chain. Capybara finds auto-scroll, which yanks
  # the layout mid-gesture and strands coordinates out of view — so presence waits and all
  # measuring happen through plain JS (no scrolling side effects), one boundary scroll centers
  # both ends, and a single chain presses, travels, and releases. Drops land on frame edges:
  # pinned bottom edge pins, unpinned top edge unpins; both resolve through the containers'
  # drop zones, immune to rows sliding around mid-drag.
  def drag_boundary(source_record, zone:, grab: :center)
    find_any_row(source_record)
    scroll_row_into_view(source_record)
    sxy = grab == :title ? js_title_of_row(source_record.id) : js_center_of_row(source_record.id)
    txy = zone == "pinned" ? js_pinned_edge : js_unpinned_edge

    perform_drop do
      page.driver.browser.action
        .move_to_location(sxy[0], sxy[1])
        .click_and_hold
        .move_by(0, 10)
        .move_to_location(txy[0], txy[1])
        .pause
        .release
        .perform
    end
  end

  def js_center_of_row(id)
    page.evaluate_script(
      "(function(){ var el = document.querySelector('#nav-conversations [data-sortable-id=\"RID\"]'); var r = el.getBoundingClientRect(); return [r.x + r.width / 2, r.y + r.height / 2]; }).call(this)".gsub("RID", id.to_s)
    ).map(&:to_i)
  end

  def js_title_of_row(id)
    page.evaluate_script(
      "(function(){ var el = document.querySelector('#nav-conversations [data-sortable-id=\"RID\"]'); var r = el.getBoundingClientRect(); return [r.x + r.width * 0.25, r.y + r.height / 2]; }).call(this)".gsub("RID", id.to_s)
    ).map(&:to_i)
  end

  def js_pinned_edge
    page.evaluate_script(
      "(function(){ var f = document.getElementById('pinned-conversations'); var r = f.getBoundingClientRect(); return [r.x + r.width / 2, r.y + r.height - 4]; }).call(this)"
    ).map(&:to_i)
  end

  def js_unpinned_edge
    page.evaluate_script(
      "(function(){ var f = document.getElementById('conversations'); var r = f.getBoundingClientRect(); return [r.x + r.width / 2, r.y + 4]; }).call(this)"
    ).map(&:to_i)
  end

  def center_of(element)
    page.evaluate_script(
      "(function(el){ var r = el.getBoundingClientRect(); return [r.x + r.width / 2, r.y + r.height / 2]; })(arguments[0])",
      element.base.native
    ).map(&:to_i)
  end
end
