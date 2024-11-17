namespace :models do
  desc "Export language models to a file, defaulting to models.yaml"
  task :export, [:path] => :environment do |t, args|
    args.with_defaults(path: Rails.root.join("models.yaml"))
    models = User.first.language_models.not_deleted.includes(:api_service)
    LanguageModel.export_to_file(path: args[:path], models:)
  end

  desc "Import language models to all users from a file, defaulting to models.yaml"
  task :import, [:path] => :environment do |t, args|
    args.with_defaults(path: Rails.root.join("models.yaml"))
    users = User.all
    LanguageModel.import_from_file(path: args[:path], users:)
  end
end
