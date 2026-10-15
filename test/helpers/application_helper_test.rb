require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  include RailsHeroicon::Helper


  test "only at most 2 initials" do
    assert_equal "jz", at_most_two_initials("jdz")
  end

  test "single initials allowed" do
    assert_equal "q", at_most_two_initials("q")
  end

  test "nil returns nil" do
    assert_nil at_most_two_initials(nil)
  end

  test "can have numbers" do
    assert_equal "P2", at_most_two_initials("P2")
  end

  test "does not change case" do
    assert_equal "p2", at_most_two_initials("p2")
  end

  test "returns the correct two initials when there are more than two" do
    assert_equal "kS", at_most_two_initials("kRxS")
  end

  test "can have spaces" do
    assert_equal "pQ", at_most_two_initials("p v Q")
  end

  test "square_size_classes spells out the width and height so tailwind can find them" do
    assert_equal "w-7 h-7", square_size_classes(7)
  end

  test "square_size_classes raises on a size tailwind would not have generated" do
    assert_raises(KeyError) { square_size_classes(99) }
  end

  test "spinner is sized through square_size_classes" do
    assert_includes spinner(size: 6), "w-6 h-6"
  end

  test "action_icon renders an outline icon in the muted zinc style" do
    html = action_icon("x-mark", title: "Close")
    assert_includes html, "text-zinc-600", "action_icon should apply the default muted classes"
    assert_includes html, "width: 22px", "action_icon should default to size 22"
    assert_includes html, 'data-tip="Close"', "action_icon should pass the title through as a tooltip"
  end

  test "action_icon lets the caller override the class" do
    html = action_icon("x-mark", class: "stroke-2 text-red-500")
    assert_includes html, "text-red-500", "a caller's class should be used"
    refute_includes html, "text-zinc-600", "a caller's class should replace the default rather than add to it"
  end

  test "labeled_text_field wraps a label and a styled text field" do
    form = ActionView::Helpers::FormBuilder.new(:assistant, assistants(:samantha), self, {})
    html = labeled_text_field(form, :name, "Name", autofocus: true)
    assert_includes html, '<div class="my-5">', "the field should sit in the spaced wrapper"
    assert_includes html, '<label for="assistant_name">Name</label>', "the label should use the given text"
    assert_includes html, 'autofocus="autofocus"', "extra options should reach the text field"
    assert_includes html, "dark:text-black", "the text field should get the shared input classes"
  end

  # Profile picture helper tests
  test "user_avatar_image_tag returns nil when user has no profile picture" do
    user = users(:keith)
    assert_nil user_avatar_image_tag(user)
  end

  test "user_avatar_image_tag returns image tag when user has profile picture" do
    user = users(:keith)
    user.profile_picture.attach(
      io: StringIO.new("fake image data"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )

    result = user_avatar_image_tag(user)
    assert_not_nil result
    assert_includes result, "img"
    assert_includes result, "test.jpg"
  end

  test "user_avatar_url returns fallback when user has no profile picture" do
    user = users(:keith)
    fallback_url = "http://example.com/default.jpg"

    assert_equal fallback_url, user_avatar_url(user, fallback: fallback_url)
  end

  test "user_avatar_url returns profile picture URL when user has profile picture" do
    user = users(:keith)
    user.profile_picture.attach(
      io: StringIO.new("fake image data"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )

    result = user_avatar_url(user)
    assert_not_nil result
    assert_includes result, "test.jpg"
  end

end
