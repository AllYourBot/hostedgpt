require "test_helper"

class Toolbox::MemoryTest < ActiveSupport::TestCase
  setup do
    @memory = Toolbox::Memory.new
  end

  test "remember_detail_about_user creates a new memory with Current set" do
    assert_difference "Memory.count", 1 do
      Current.set(user: users(:keith), message: messages(:photo_identified)) do
        @memory.remember_detail_about_user(detail_s: "Keith owns a cat")
      end
    end

    new_memory = Memory.last
    assert_equal users(:keith), new_memory.user
    assert_equal messages(:identify_photo), new_memory.message
  end

  test "remember_detail_about_user DOES NOT creates a new memory without Current" do
    assert_no_difference "Memory.count" do
      assert_raises do
        @memory.remember_detail_about_user(detail_s: "Keith owns a cat")
      end
    end
  end
end
