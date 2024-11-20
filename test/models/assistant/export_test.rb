require "test_helper"

class Assistant::ExportTest < ActiveSupport::TestCase
  test "as_json includes language_model_api_name" do
    assistant = assistants(:keith_gpt4)
    assert assistant.as_json.key?("language_model_api_name")
  end

  test "language_model can be nil" do
    assert_nil Assistant.new(language_model: nil).as_json["language_model_api_name"]
  end

  test "except api_service_name" do
    assistant = assistants(:rob_gpt4)
    assert_nil assistant.as_json(except: ["language_model_api_name"])["language_model_api_name"]
  end

  test "export_to_file json" do
    path = Rails.root.join("tmp/assistants.json")
    Assistant.export_to_file(path:, assistants: users(:keith).assistants.not_deleted)
    assert File.exist?(path)
    storage = JSON.load_file(path)
    assistants = storage["assistants"]
    assert_equal assistants.first.keys.sort, %w[name description instructions tools language_model_api_name].sort
  end

  test "export_to_file yaml" do
    path = Rails.root.join("tmp/assistants.yml")
    Assistant.export_to_file(path:, assistants: users(:keith).assistants.not_deleted)
    assert File.exist?(path)
    storage = YAML.load_file(path)
    assistants = storage["assistants"]
    assert_equal assistants.first.keys.sort, %w[name description instructions tools language_model_api_name].sort
  end

  test "import_from_file with only new models" do
    user = users(:keith)
    user.assistants.destroy_all
    assistants = [{
      name: "new assistant",
      description: "new description",
      instructions: "new instructions",
      tools: "new tools",
      external_id: "new external_id",
      language_model_api_name: language_models(:gpt_4o).api_name
    }]
    storage = {
      "assistants" => assistants
    }
    path = Rails.root.join("tmp/newmodels.yml")
    File.write(path, storage.to_yaml)
    assert_difference "Assistant.count", 1 do
      Assistant.import_from_file(path:, users: [user])
    end
    assert user.assistants.find_by(external_id: "new external_id")
  end

  test "import_from_file json with only new models" do
    user = users(:keith)
    user.assistants.destroy_all
    assistants = [{
      name: "new assistant",
      description: "new description",
      instructions: "new instructions",
      tools: "new tools",
      external_id: "new external_id",
      language_model_api_name: language_models(:gpt_4o).api_name
    }]
    storage = {
      "assistants" => assistants
    }
    path = Rails.root.join("tmp/newmodels.json")
    File.write(path, storage.to_json)
    assert_difference "Assistant.count", 1 do
      Assistant.import_from_file(path:, users: [user])
    end
    assert user.assistants.find_by(external_id: "new external_id")
  end

  test "import_from_file with existing models by name" do
    user = users(:keith)
    assistant = user.assistants.not_deleted.first
    assistants = [{
      name: assistant.name,
      description: "new description",
      instructions: "new instructions",
      tools: "new tools",
      external_id: "new external_id",
      language_model_api_name: language_models(:gpt_4o).api_name
    }]
    storage = {
      "assistants" => assistants
    }
    path = Rails.root.join("tmp/newmodels.yml")
    File.write(path, storage.to_yaml)
    assert_no_difference "Assistant.count" do
      Assistant.import_from_file(path:, users: [user])
    end
    assistant.reload
    assert_equal "new description", assistant.description
    assert_equal "new instructions", assistant.instructions
    assert_equal "new tools", assistant.tools
    assert_equal "new external_id", assistant.external_id
    assert_equal language_models(:gpt_4o).api_name, assistant.language_model_api_name
  end
end
