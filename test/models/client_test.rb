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

  test "authenticated scope only gives the clients with an active authentication" do
    ids = [ clients(:rob_browser).id, clients(:keith_desktop_browser).id ]
    assert_equal 2, Client.where(id: ids).count

    assert_equal 1, Client.authenticated.where(id: ids).count
    refute clients(:rob_browser).authenticated?
    assert clients(:keith_desktop_browser).authenticated?
  end

  test "simple create works and token is generated" do
    assert_nothing_raised do
      Client.create!(person: people(:keith_registered), platform: :ios)
    end

    assert_not_nil Client.last.token
  end

  test "authenticated? returns the correct value" do
    assert clients(:keith_desktop_browser).authenticated?
    refute clients(:rob_browser).authenticated?
  end

  test "authenticate_with creates a new authentication for a logged out client" do
    rob_browser = clients(:rob_browser)

    assert_difference "Authentication.count", 1 do
      assert_changes "rob_browser.authentication", from: nil do
        rob_browser.authenticate_with! credentials(:rob_password)
      end
    end

    assert_equal credentials(:rob_password), rob_browser.authentication.credential
  end

  test "authenticate_with creates a new authentication AND LOGS OUT a client that is currently authenticated" do
    keith_browser = clients(:keith_desktop_browser)
    old_authentication = keith_browser.authentication

    assert old_authentication, "This client should start out already authenticated"
    assert_difference "Authentication.count", 1 do
      assert_changes "keith_browser.authentication" do
        keith_browser.authenticate_with! credentials(:keith_password)
      end
    end

    assert_equal credentials(:keith_password), keith_browser.authentication.credential
    assert old_authentication.reload.deleted_at, "The old authentication should be deleted"
  end

  test "bearer_token returns nil for NON-API clients AND token for API clients" do
    assert_nil clients(:keith_desktop_browser).bearer_token
    assert_equal "#{clients(:keith_api).id}:#{clients(:keith_api).token}", clients(:keith_api).bearer_token
  end
end
