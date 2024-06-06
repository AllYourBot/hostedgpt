require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "has an associated person" do
    assert_instance_of Person, clients(:keith_desktop_browser).person
  end

  test "has an authentication" do
    assert_instance_of Authentication, clients(:keith_desktop_browser).authentication
  end

  test "has many authentications_including_deleted" do
    assert_instance_of Authentication, clients(:keith_desktop_browser).authentications_including_deleted.first
  end

  test "associations are deleted upon destroy" do
    assert_difference "Authentication.count", -clients(:keith_desktop_browser).authentications_including_deleted.count do
      clients(:keith_desktop_browser).destroy
    end
  end

  test "simple create works" do
    assert_nothing_raised do
      Client.create!(person: people(:keith_registered), platform: :ios, format: :phone)
    end
  end
end
