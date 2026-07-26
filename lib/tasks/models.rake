namespace :models do
  desc "Export language models to a file, defaulting to models.yml"
  task :export, [:path] => :environment do |t, args|
    args.with_defaults(path: Rails.root.join(LanguageModel::Export::DEFAULT_MODEL_FILE))
    warn "Exporting language models to #{args[:path]}"
    unless User.first
      warn "No users found, unable to export language models"
      exit 1
    end
    models = User.first.language_models.ordered.not_deleted.includes(:api_service)
    LanguageModel.export_to_file(path: args[:path], models:)
  end

  desc "Import language models to all users from a file, defaulting to models.yml"
  task :import, [:path] => :environment do |t, args|
    args.with_defaults(path: Rails.root.join(LanguageModel::Export::DEFAULT_MODEL_FILE))
    warn "Importing language models from #{args[:path]}"
    users = User.all
    LanguageModel.import_from_file(path: args[:path], users:)
  end

  desc "Refresh RubyLLM model registry from models.dev and save to config/models.json"
  task :update_rubyllm => :environment do
    path = Rails.root.join("config/models.json")
    RubyLLM.models.refresh!
    RubyLLM.models.save_to_json(path.to_s)
    warn "Saved #{RubyLLM.models.count} models to #{path}"
  end

  desc "Import RubyLLM model registry into LanguageModel records for all users"
  task :import_rubyllm => :environment do
    count = LanguageModel.import_rubyllm_registry
    warn "Imported #{count} language models from RubyLLM registry"
  end
end

Rake::Task["db:prepare"].enhance do
  Rake::Task["models:import"].invoke
  Rake::Task["assistants:import"].invoke
  begin
    Rake::Task["models:import_rubyllm"].invoke if Feature.rubyllm?
  rescue => e
    warn "RubyLLM registry import failed: #{e.message}"
  end
end
