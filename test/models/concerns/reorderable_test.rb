require "test_helper"

class ReorderableTest < ActiveSupport::TestCase
  setup do
    @keith = users(:keith)
    @keith.assistants.reposition(@keith.assistants.ordered.pluck(:id)) # normalize to 0..n-1
  end

  test "a new assistant lands at the top, above soft-deleted ones too" do
    @keith.assistants.first.update_column(:deleted_at, Time.current)
    min_before = @keith.assistants_including_deleted.minimum(:position)

    assistant = @keith.assistants.create!(name: "Newcomer", language_model: language_models(:gpt_4o))

    assert_equal min_before - 1, assistant.position
    assert_equal assistant, @keith.assistants.ordered.first
  end

  test "reorder_scope includes soft-deleted assistants because their positions still hold places" do
    deleted = @keith.assistants.first
    deleted.update_column(:deleted_at, Time.current)

    assert_includes Assistant.reorder_scope(@keith).pluck(:id), deleted.id
  end

  test "insert_at moves an assistant up and slides the ones it passes down" do
    ids = @keith.assistants.ordered.pluck(:id)
    moved = Assistant.find(ids.second)

    moved.insert_at(0)

    assert_equal 0, moved.reload.position
    assert_equal [ids.second] + ids[0...1] + ids[2..], @keith.assistants.ordered.pluck(:id)
    assert_equal (0...ids.length).to_a, @keith.assistants.ordered.pluck(:position).sort
  end

  test "insert_at moves an assistant down and slides the ones it passes up" do
    ids = @keith.assistants.ordered.pluck(:id)
    moved = Assistant.find(ids.first)

    moved.insert_at(ids.length - 1)

    assert_equal ids.length - 1, moved.reload.position
    assert_equal ids[1..] + [ids.first], @keith.assistants.ordered.pluck(:id)
    assert_equal (0...ids.length).to_a, @keith.assistants.ordered.pluck(:position).sort
  end

  test "insert_at at the current position changes nothing" do
    before = @keith.assistants.ordered.pluck(:id, :position)
    moved = @keith.assistants.ordered.second

    moved.insert_at(moved.position)

    assert_equal before, @keith.assistants.ordered.pluck(:id, :position)
  end
end
