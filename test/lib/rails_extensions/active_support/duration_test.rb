require "test_helper"

class ActiveSupport::DurationTest < ActiveSupport::TestCase

  test "as_sentence with 1 year" do
    duration = 1.year
    assert_equal "1 year", duration.as_sentence
  end

  test "as_sentence with multiple years" do
    duration = 2.year
    assert_equal "2 years", duration.as_sentence
  end

  test "as_sentence with 1 month" do
    duration = 1.month
    assert_equal "1 month", duration.as_sentence
  end

  test "as_sentence with multiple months" do
    duration = 2.month
    assert_equal "2 months", duration.as_sentence
  end

  test "as_sentence with more months than are in a year" do
    duration = 13.month
    assert_match %r{1 year.+}, duration.as_sentence
  end

  test "as_sentence with 1 week" do
    duration = 1.week
    assert_equal "1 week", duration.as_sentence
  end

  test "as_sentence with multiple weeks" do
    duration = 2.week
    assert_equal "2 weeks", duration.as_sentence
  end

  test "as_sentence with more weeks than are in a month" do
    duration = 5.week
    assert_match %r{1 month.+}, duration.as_sentence
  end

  test "as_sentence with 1 day" do
    duration = 1.day
    assert_equal "1 day", duration.as_sentence
  end

  test "as_sentence with multiple days" do
    duration = 2.day
    assert_equal "2 days", duration.as_sentence
  end

  test "as_sentence with more days than are in a week" do
    duration = 8.day
    assert_match %r{1 week.+}, duration.as_sentence
  end

  test "as_sentence with 1 hour" do
    duration = 1.hour
    assert_equal "1 hour", duration.as_sentence
  end

  test "as_sentence with multiple hours" do
    duration = 2.hour
    assert_equal "2 hours", duration.as_sentence
  end

  test "as_sentence with more hours than are in a day" do
    duration = 25.hour
    assert_match %r{1 day.+}, duration.as_sentence
  end

  test "as_sentence with 1 minute" do
    duration = 1.minute
    assert_equal "1 minute", duration.as_sentence
  end

  test "as_sentence with multiple minutes" do
    duration = 2.minute
    assert_equal "2 minutes", duration.as_sentence
  end

  test "as_sentence with more minutes than are in an hour" do
    duration = 61.minute
    assert_match %r{1 hour.+}, duration.as_sentence
  end

  test "as_sentence with 1 second" do
    duration = 1.second
    assert_equal "1 second", duration.as_sentence
  end

  test "as_sentence with multiple seconds" do
    duration = 2.second
    assert_equal "2 seconds", duration.as_sentence
  end

  test "as_sentence with more seconds than are in a minute" do
    duration = 61.second
    assert_match %r{1 minute.+}, duration.as_sentence
  end

end
