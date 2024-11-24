require "test_helper"

class LanguageModel::ExportTest < ActiveSupport::TestCase
  test "as_json includes api_service_name" do
    language_model = LanguageModel.new(api_service: api_services(:rob_openai_service))
    assert language_model.as_json.key?("api_service_name")
  end

  test "api_service can be nil" do
    assert_nil LanguageModel.new(api_service: nil).as_json["api_service_name"]
  end

  test "except api_service_name" do
    language_model = LanguageModel.new(api_service: api_services(:rob_openai_service))
    assert_nil language_model.as_json(except: ["api_service_name"])["api_service_name"]
  end

  test "export_to_file json" do
    path = Rails.root.join("tmp/models.json")
    LanguageModel.export_to_file(path:, models: users(:rob).language_models.not_deleted)
    assert File.exist?(path)
    storage = JSON.load_file(path)
    models = storage["models"]
    assert_equal models.first.keys.sort, %w[api_name name best supports_images supports_tools supports_system_message input_token_cost_cents output_token_cost_cents api_service_name].sort
  end

  test "export_to_file yaml" do
    path = Rails.root.join("tmp/models.yml")
    LanguageModel.export_to_file(path:, models: users(:rob).language_models.not_deleted)
    assert File.exist?(path)
    storage = YAML.load_file(path)
    models = storage["models"]
    assert_equal models.first.keys.sort, %w[api_name name best supports_images supports_tools supports_system_message input_token_cost_cents output_token_cost_cents api_service_name].sort
  end

  test "import_from_file with only new models" do
    models = [{
      api_name: "new-model",
      name: "new model",
      api_service_name: api_services(:rob_openai_service).name,
      supports_images: true,
      supports_tools: true,
      input_token_cost_cents: 1,
      output_token_cost_cents: 1
    }]
    storage = {
      "models" => models
    }
    path = Rails.root.join("tmp/newmodels.yml")
    File.write(path, storage.to_yaml)
    assert_difference "LanguageModel.count", 1 do
      LanguageModel.import_from_file(path:, users: users(:rob))
    end
    assert users(:rob).language_models.find_by(api_name: "new-model")
  end

  test "import_from_file json with only new models" do
    models = [{
      api_name: "new-model",
      name: "new model",
      api_service_name: api_services(:rob_openai_service).name,
      supports_images: true,
      supports_tools: true,
      input_token_cost_cents: 1,
      output_token_cost_cents: 1
    }]
    storage = {
      "models" => models
    }
    path = Rails.root.join("tmp/newmodels.json")
    File.write(path, storage.to_json)
    assert_difference "LanguageModel.count", 1 do
      LanguageModel.import_from_file(path:, users: users(:rob))
    end
    assert users(:rob).language_models.find_by(api_name: "new-model")
  end

  test "import_from_file with existing models by api_name" do
    model = users(:rob).language_models.not_deleted.first
    models = [{
      api_name: model.api_name,
      name: "new name",
      supports_images: false,
      supports_tools: true,
      input_token_cost_cents: 0.0001,
      output_token_cost_cents: 0.0001
    }]
    storage = {
      "models" => models
    }
    path = Rails.root.join("tmp/newmodels.yml")
    File.write(path, storage.to_yaml)
    # TODO: Get this working again
    # assert_no_difference "LanguageModel.count" do
    #  LanguageModel.import_from_file(path:, users: users(:rob))
    # end
    model.reload
    # assert_equal "new name", model.name
    assert_equal false, model.supports_images
    assert_equal true, model.supports_tools
    assert_equal 0.0001, model.input_token_cost_cents
    assert_equal 0.0001, model.output_token_cost_cents
  end
end
