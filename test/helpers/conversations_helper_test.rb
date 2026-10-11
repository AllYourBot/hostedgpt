require "test_helper"

class ConversationsHelperTest < ActionView::TestCase
  # The sidebar groups by static English model keys and translates at the display layer,
  # so every bucket must resolve in both locales — the German half of this regressed once
  # when the helper and its keys were retired with the old grouped sidebar.
  ENGLISH = {
    "Today" => "Today",
    "Yesterday" => "Yesterday",
    "This Week" => "This Week",
    "This Month" => "This Month",
    "Last Month" => "Last Month",
    "Older" => "Older"
  }.freeze

  GERMAN = {
    "Today" => "Heute",
    "Yesterday" => "Gestern",
    "This Week" => "Diese Woche",
    "This Month" => "Diesen Monat",
    "Last Month" => "Letzten Monat",
    "Older" => "Älter"
  }.freeze

  test "translates every time span in English" do
    I18n.with_locale(:en) do
      ENGLISH.each do |span, expected|
        assert_equal expected, translated_time_span(span)
      end
    end
  end

  test "translates every time span in German" do
    I18n.with_locale(:de) do
      GERMAN.each do |span, expected|
        assert_equal expected, translated_time_span(span)
      end
    end
  end
end
