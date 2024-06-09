require "test_helper"

class FeatureTest < ActiveSupport::TestCase

  test "should return value of feature" do
    stub_features(my_feature: true) do
      assert Feature.enabled?(:my_feature)
      assert Feature.my_feature?
    end

    stub_features(my_feature: false) do
      refute Feature.enabled?(:my_feature)
      refute Feature.my_feature?
    end
  end

  test "disabled? returns the opposite" do
    stub_features(my_feature: false) do
      refute Feature.enabled?(:my_feature)
      assert Feature.disabled?(:my_feature)
    end
  end

  test "boolean strings are read as booleans" do
    stub_features(my_feature: "true") do
      assert Feature.enabled?(:my_feature)
    end

    stub_features(my_feature: "false") do
      refute Feature.enabled?(:my_feature)
    end
  end

  test "password and google auth are DISABLED if HTTP header auth is ENABLED" do
    stub_features(
      http_header_authentication: true,
      password_authentication: true,
      google_authentication: true,
    ) do
      assert Feature.enabled?(:http_header_authentication)
      assert Feature.http_header_authentication?
      refute Feature.enabled?(:password_authentication)
      refute Feature.password_authentication?
      refute Feature.enabled?(:google_authentication)
      refute Feature.google_authentication?
    end
  end

  test "password and google auth are ALLOWED if HTTP header auth is DISABLED" do

    stub_features(
      http_header_authentication: false,
      password_authentication: true,
      google_authentication: false,
     ) do
      refute Feature.enabled?(:http_header_authentication)
      refute Feature.http_header_authentication?
      assert Feature.enabled?(:password_authentication)
      assert Feature.password_authentication?
      refute Feature.enabled?(:google_authentication)
      refute Feature.google_authentication?
    end
  end

  test "referencing a feature that does not exist raises an exception" do
    assert_raises do
      Feature.foobar?
    end
  end
end
