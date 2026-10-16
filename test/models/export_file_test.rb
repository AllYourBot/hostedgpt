require "test_helper"

class ExportFileTest < ActiveSupport::TestCase
  test "writes YAML unless the path ends in .json" do
    Tempfile.create(["export", ".yml"]) do |file|
      ExportFile.write(file.path, "models" => [{ "name" => "a" }])
      assert_equal({ "models" => [{ "name" => "a" }] }, YAML.load_file(file.path), "A .yml path should get YAML")
    end
  end

  test "writes JSON when the path ends in .json" do
    Tempfile.create(["export", ".json"]) do |file|
      ExportFile.write(Pathname.new(file.path), "models" => [{ "name" => "a" }])
      assert_equal({ "models" => [{ "name" => "a" }] }, JSON.parse(File.read(file.path)), "A .json path should get JSON")
    end
  end
end
