require "application_system_test_case"

class MessagesComposerAutogrowTest < ApplicationSystemTestCase
  setup do
    login_as users(:keith)
    @long_conversation = conversations(:greeting)
  end

  test "textarea grows in height as newlines are added and shrinks in height when they are removed" do
    click_text @long_conversation.title
    wait_for_images_to_load

    send_keys "1"

    height = composer.native.property('clientHeight')
    assert_stays_at_bottom do
      send_keys "shift+enter"
      sleep 0.3
    end
    assert composer.native.property('clientHeight') > height, "Input should have grown taller"

    height = composer.native.property('clientHeight')
    assert_stays_at_bottom do
      send_keys "2"
      send_keys "shift+enter"
      sleep 0.3
    end
    assert composer.native.property('clientHeight') > height, "Input should have grown taller"

    height = composer.native.property('clientHeight')
    assert_stays_at_bottom do
      send_keys "backspace"
      sleep 0.3
    end
    assert composer.native.property('clientHeight') < height, "Input should have gotten shorter"

    height = composer.native.property('clientHeight')
    assert_stays_at_bottom do
      send_keys "backspace+backspace"
      sleep 0.3
    end
    assert composer.native.property('clientHeight') < height, "Input should have gotten shorter"

    height = composer.native.property('clientHeight')
    assert_stays_at_bottom do
      send_keys "backspace+backspace"
      sleep 0.3
    end
    assert composer.native.property('clientHeight') == height, "Input should not have changed height"
  end

  test "when large block of text is pasted, textarea grows in height and auto-scrolls to stay at the bottom" do
    click_text @long_conversation.title
    wait_for_images_to_load

    height = composer.native.property('clientHeight')
    assert_stays_at_bottom do
      send_keys long_input_text

      assert_true "Input should have grown taller" do
        composer.native.property('clientHeight') > height
      end
    end
  end

  test "when large block of text is pasted, textarea grows in height and DOES NOT auto-scroll so what scrolled to stays visible" do
    click_text @long_conversation.title
    wait_for_images_to_load

    assert_at_bottom
    assert_scrolled_up { scroll_to find_messages.second }

    height = composer.native.property('clientHeight')
    assert_did_not_scroll do
      send_keys long_input_text

      assert_true "Input should have grown taller" do
        composer.native.property('clientHeight') > height
      end
    end
  end

  private

  def long_input_text
    text = <<~END
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
    END
    text.gsub(/\n/, ' ')
  end
end
