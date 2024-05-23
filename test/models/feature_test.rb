require "test_helper"

class FeatureTest < ActiveSupport::TestCase
  test "should return value of feature" do
    Feature.stub :features, { my_feature: true } do
      assert Feature.enabled?(:my_feature)
      assert Feature.my_feature?
    end

    Feature.stub :features, { my_feature: false } do
      refute Feature.enabled?(:my_feature)
      refute Feature.my_feature?
    end
  end

  test "should default to false when feature not found" do
    refute Feature.enabled?(:fake)
    refute Feature.fake?
  end

  test "boolean strings are read as booleans" do
    Feature.stub :features, { my_feature: "true" } do
      assert Feature.enabled?(:my_feature)
    end

    Feature.stub :features, { my_feature: "false" } do
      refute Feature.enabled?(:my_feature)
    end
  end

end
