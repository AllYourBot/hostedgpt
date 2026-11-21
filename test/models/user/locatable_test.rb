require "test_helper"

class User::LocatableTest < ActiveSupport::TestCase
  setup do
    @user = users(:keith)
  end

  test "use_ip_location defaults to off and takes a form checkbox value" do
    refute @user.use_ip_location?, "Using the IP location should be off for a user who never changed the setting"

    @user.update!(use_ip_location: "1")
    assert @user.reload.use_ip_location?, "Checking the box should turn it on"
    assert_equal true, @user.preferences["use_ip_location"], "The preference should be stored as a boolean"
  end

  test "located_at! does nothing while the setting is off" do
    @user.located_at!("1.2.3.4")
    assert_nil @user.reload.ip_location, "No IP address should be stored while the setting is off"
  end

  test "located_at! stores a new address and forgets the old place" do
    @user.update!(use_ip_location: true, ip_location: { "ip" => "5.6.7.8", "name" => "Paris, FR" })

    @user.located_at!("1.2.3.4")
    assert_equal({ "ip" => "1.2.3.4" }, @user.reload.ip_location, "A new address should replace the old place")
  end

  test "located_at! keeps the place when the address is unchanged" do
    @user.update!(use_ip_location: true, ip_location: { "ip" => "1.2.3.4", "name" => "Austin, Texas, US" })

    @user.located_at!("1.2.3.4")
    assert_equal "Austin, Texas, US", @user.reload.ip_location["name"], "The remembered place should be kept"
  end

  test "location looks the place up once and remembers it" do
    @user.update!(use_ip_location: true, ip_location: { "ip" => "1.2.3.4" })

    stub_get_response(:get_location, status: 200, response: { city: "Austin", region: "Texas", country: "US" }) do
      assert_equal "Austin, Texas, US", @user.location, "The place should be looked up from the address"
    end
    assert_equal "Austin, Texas, US", @user.reload.location, "The place should be remembered without another lookup"
  end

  test "location is nil while the setting is off" do
    @user.update!(ip_location: { "ip" => "1.2.3.4", "name" => "Austin, Texas, US" })
    assert_nil @user.location, "No location should be given while the setting is off"
  end

  test "turning the setting off forgets the address and place" do
    @user.update!(use_ip_location: true, ip_location: { "ip" => "1.2.3.4", "name" => "Austin, Texas, US" })

    @user.update!(use_ip_location: "0")
    assert_nil @user.reload.ip_location, "Turning the setting off should forget the stored location"
  end
end
