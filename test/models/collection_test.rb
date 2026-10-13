require "test_helper"

class CollectionTest < ActiveSupport::TestCase
  # Association tests

  test "has an associated user" do
    assert_instance_of User, collections(:recipes).user
  end

  test "has associated documents" do
    assert_includes collections(:recipes).documents, documents(:lasagna_recipe), "The recipes collection should hold the lasagna recipe"
  end

  test "ordered sorts by name" do
    users(:keith).collections.create!(name: "Books")

    assert_equal ["Books", "Recipes"], users(:keith).collections.ordered.map(&:name), "Collections should be sorted alphabetically"
  end

  # Creation tests

  test "create with minimal possible attributes" do
    assert_nothing_raised do
      Collection.create!(user: users(:keith), name: "Books")
    end
  end

  test "new enforces all required attributes" do
    collection = Collection.new
    collection.validate

    assert_equal ["must exist"], collection.errors[:user], "A collection needs a user"
    assert_equal ["can't be blank"], collection.errors[:name], "A collection needs a name"
  end

  # Destroy test

  test "associations are destroyed upon destroy" do
    assert_difference "Document.count", -collections(:recipes).documents.count do
      collections(:recipes).destroy
    end
  end
end
