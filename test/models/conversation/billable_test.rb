require "test_helper"

class Conversation::BillableTest < ActiveSupport::TestCase
  test "executing reset methods resets the rollups" do
    originals = conversations(:debugging).attributes.symbolize_keys.slice(
      :input_token_total_cost,
      :output_token_total_cost,
      :input_token_total_count,
      :output_token_total_count
    )

    conversations(:debugging).update!(
      input_token_total_cost: 0,
      output_token_total_cost: 0,
      input_token_total_count: 0,
      output_token_total_count: 0,
    )

    assert_equal 0, conversations(:debugging).input_token_total_cost
    assert_equal 0, conversations(:debugging).output_token_total_cost
    assert_equal 0, conversations(:debugging).input_token_total_count
    assert_equal 0, conversations(:debugging).output_token_total_count

    conversations(:debugging).reset_input_token_total_cost!
    conversations(:debugging).reset_output_token_total_cost!
    conversations(:debugging).reset_input_token_total_count!
    conversations(:debugging).reset_output_token_total_count!

    conversations(:debugging).reload

    assert_equal originals[:input_token_total_cost], conversations(:debugging).input_token_total_cost
    assert_equal originals[:output_token_total_cost], conversations(:debugging).output_token_total_cost
    assert_equal originals[:input_token_total_count], conversations(:debugging).input_token_total_count
    assert_equal originals[:output_token_total_count], conversations(:debugging).output_token_total_count
  end

  test "removing a message decrements counts" do
    originals = conversations(:debugging).attributes.symbolize_keys.slice(
      :input_token_total_cost,
      :output_token_total_cost,
      :input_token_total_count,
      :output_token_total_count
    )

    message = conversations(:debugging).messages.first
    adjustments = message.attributes.symbolize_keys.slice(:input_token_cost, :output_token_cost, :input_token_count, :output_token_count)
    message.destroy

    adjusted = conversations(:debugging).reload.attributes.symbolize_keys.slice(
      :input_token_total_cost,
      :output_token_total_cost,
      :input_token_total_count,
      :output_token_total_count
    )

    assert_equal adjusted[:input_token_total_cost], originals[:input_token_total_cost] - adjustments[:input_token_cost]
    assert_equal adjusted[:output_token_total_cost], originals[:output_token_total_cost] - adjustments[:output_token_cost]
    assert_equal adjusted[:input_token_total_count], originals[:input_token_total_count] - adjustments[:input_token_count]
    assert_equal adjusted[:output_token_total_count], originals[:output_token_total_count] - adjustments[:output_token_count]
  end

  test "adding a message increments counts" do
    originals = conversations(:debugging).attributes.symbolize_keys.slice(
      :input_token_total_cost,
      :output_token_total_cost,
      :input_token_total_count,
      :output_token_total_count
    )

    message = conversations(:debugging).messages.create!(
      assistant: assistants(:rob_gpt4),
      content_text: "What is your name?",
      input_token_count: 1,
      output_token_count: 2,
      input_token_cost: 0.1,
      output_token_cost: 0.2
    )
    adjustments = message.attributes.symbolize_keys.slice(:input_token_cost, :output_token_cost, :input_token_count, :output_token_count)

    adjusted = conversations(:debugging).reload.attributes.symbolize_keys.slice(
      :input_token_total_cost,
      :output_token_total_cost,
      :input_token_total_count,
      :output_token_total_count
    )

    assert_equal adjusted[:input_token_total_cost], originals[:input_token_total_cost] + adjustments[:input_token_cost]
    assert_equal adjusted[:output_token_total_cost], originals[:output_token_total_cost] + adjustments[:output_token_cost]
    assert_equal adjusted[:input_token_total_count], originals[:input_token_total_count] + adjustments[:input_token_count]
    assert_equal adjusted[:output_token_total_count], originals[:output_token_total_count] + adjustments[:output_token_count]
  end
end
