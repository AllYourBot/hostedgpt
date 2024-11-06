namespace :models do
  desc "Export language models to a file, defaulting to models.yaml"
  task :export, [:path] => :environment do |t, args|
    args.with_defaults(path: Rails.root.join("models.yaml"))
    LanguageModel.export_to_file(path: args[:path])
  end
end
