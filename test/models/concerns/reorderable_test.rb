require "test_helper"

class ReorderableTest < ActiveSupport::TestCase
  setup do
    @keith = users(:keith)
    Assistant.reposition(@keith, @keith.assistants.ordered.pluck(:id)) # normalize to 0..n-1
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

  test "insert_at from a nil slot claims it and slides the target down" do
    ids = @keith.assistants.ordered.pluck(:id)
    moved = Assistant.find(ids.second)
    moved.update_column(:position, nil)

    moved.insert_at(0)

    assert_equal 0, moved.reload.position
    assert_equal [ids.second] + ids[0...1] + ids[2..], @keith.assistants.ordered.pluck(:id)
  end

  test "reposition numbers duplicate ids densely without double-counting" do
    ids = @keith.assistants.ordered.pluck(:id)
    doubled = [ids.first, ids.first, ids.second, ids.second, ids.third]

    Assistant.reposition(@keith, doubled)

    assert_equal [ids.first, ids.second, ids.third], @keith.assistants.ordered.first(3).pluck(:id)
    assert_equal (0...ids.length).to_a, @keith.assistants.ordered.pluck(:position).sort
  end

  test "reposition numbers only posted ids, leaving the rest at their slots" do
    ids = @keith.assistants.ordered.pluck(:id)
    rest_before = Assistant.where(id: ids - [ids[2], ids[0]]).pluck(:id, :position).to_h

    Assistant.reposition(@keith, [ids[2], ids[0]])

    assert_equal 0, Assistant.find(ids[2]).position
    assert_equal 1, Assistant.find(ids[0]).position
    assert_equal rest_before, Assistant.where(id: ids - [ids[2], ids[0]]).pluck(:id, :position).to_h
  end

  test "reposition drops non-scalar ids instead of raising" do
    ids = @keith.assistants.ordered.pluck(:id)

    Assistant.reposition(@keith, { search: "x" })
    Assistant.reposition(@keith, ["not-a-number", nil, ids.first])

    assert_equal ids.first, @keith.assistants.ordered.first.id
    assert_equal (0...ids.length).to_a, @keith.assistants.ordered.pluck(:position).sort
  end

  test "duplicate positions break ties by id desc" do
    ids = @keith.assistants.ordered.pluck(:id)
    Assistant.where(id: ids.first(2)).update_all(position: 0)

    assert_equal ids.first(2).sort.reverse, @keith.assistants.ordered.first(2).pluck(:id)
  end
end
