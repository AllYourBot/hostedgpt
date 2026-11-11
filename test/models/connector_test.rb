require "test_helper"

class ConnectorTest < ActiveSupport::TestCase
  # Association tests

  test "has an associated user" do
    assert_instance_of User, connectors(:github).user
  end

  test "ordered lists connectors by name" do
    users(:keith).connectors.create!(name: "Calendar", url: "https://mcp.example.com/calendar")
    assert_equal ["Calendar", "GitHub"], users(:keith).connectors.ordered.map(&:name), "Connectors should be listed alphabetically"
  end

  # Creation tests

  test "create with minimal possible attributes" do
    assert_nothing_raised do
      Connector.create!(user: users(:keith), name: "Calendar", url: "https://mcp.example.com/calendar")
    end
  end

  test "new enforces all required attributes and formatting" do
    connector = Connector.new
    refute connector.valid?, "A connector without a user, name or URL should be invalid"
    assert_equal ["must exist"], connector.errors[:user]
    assert_equal ["can't be blank"], connector.errors[:name]
    assert_equal ["can't be blank"], connector.errors[:url]

    connector = Connector.new(user: users(:keith), name: "Files", url: "file:///etc/passwd")
    refute connector.valid?, "Only http and https URLs should be accepted"
    assert_equal ["is invalid"], connector.errors[:url]
  end

  test "create STRIPS whitespace from the url and token" do
    connector = Connector.create!(user: users(:keith), name: "Calendar", url: " https://mcp.example.com/calendar ", token: " secret\n")
    assert_equal "https://mcp.example.com/calendar", connector.url, "A pasted URL should lose its surrounding whitespace"
    assert_equal "secret", connector.token, "A pasted token should lose its surrounding whitespace"
  end

  test "create ENCRYPTS the token" do
    connector = Connector.create!(user: users(:keith), name: "Calendar", url: "https://mcp.example.com/calendar", token: "secret")
    refute_includes connector.ciphertext_for(:token), "secret", "The token should not be stored in plain text"
  end

  # Destroy test

  test "destroy removes the connector" do
    assert_difference "Connector.count", -1 do
      connectors(:github).destroy
    end
  end
end
