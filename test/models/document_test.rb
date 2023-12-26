require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, documents(:cat_photo).user
  end

  test "has an associated assistant" do
    assert_instance_of Assistant, documents(:cat_photo).assistant
  end

  test "has an associated message" do
    assert_instance_of Message, documents(:cat_photo).message
  end

  test "simple create works" do
    assert_nothing_raised do
      Document.create!(
        user: users(:keith),
        filename: "dog_photo.jpg",
        purpose: "assistants",
        bytes: 123
      )
    end
  end

  test "associations are deleted upon destroy" do
    assert_nothing_raised do
      documents(:cat_photo).destroy!
    end
  end
end
