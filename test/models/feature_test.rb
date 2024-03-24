require "test_helper"

class FeatureTest < ActiveSupport::TestCase
  test "configuration should be an instance of ActiveSupport::OrderedOptions" do
    assert Feature.configuration.is_a?(ActiveSupport::OrderedOptions)
  end

  test "should return value of feature" do
    Feature.stub :configuration, {my_feature: true} do
      assert Feature.enabled?(:my_feature)
    end

    Feature.stub :configuration, {my_feature: false} do
      refute Feature.enabled?(:my_feature)
    end
  end

  test "should default to false when feature not found" do
    Feature.stub :configuration, {my_feature: true} do
      refute Feature.enabled?(:fake)
    end
  end
end
