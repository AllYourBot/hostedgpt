require "test_helper"

class CollectionTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, collections(:recipes).user
  end

  test "has associated documents" do
    assert_includes collections(:recipes).documents, documents(:lasagna_recipe)
  end

  test "is invalid WITHOUT a name" do
    refute Collection.new(user: users(:keith)).valid?
  end

  test "ordered sorts by name" do
    users(:keith).collections.create!(name: "Books")

    assert_equal ["Books", "Recipes"], users(:keith).collections.ordered.map(&:name)
  end
end
