namespace :models do
  desc "Export language models to a file, defaulting to models.yml"
  task :export, [:path] => :environment do |t, args|
    args.with_defaults(path: Rails.root.join(LanguageModel::Export::DEFAULT_MODEL_FILE))
    models = User.first.language_models.ordered.not_deleted.includes(:api_service)
    LanguageModel.export_to_file(path: args[:path], models:)
  end

  desc "Import language models to all users from a file, defaulting to models.yml"
  task :import, [:path] => :environment do |t, args|
    args.with_defaults(path: Rails.root.join(LanguageModel::Export::DEFAULT_MODEL_FILE))
    users = User.all
    LanguageModel.import_from_file(path: args[:path], users:)
  end
end
