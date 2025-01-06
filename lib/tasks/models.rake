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
end

Rake::Task["db:prepare"].enhance do
  Rake::Task["models:import"].invoke
  Rake::Task["assistants:import"].invoke
end
