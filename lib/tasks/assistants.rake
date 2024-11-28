namespace :assistants do
  desc "Export assistants to a file, defaulting to assistants.yml"
  task :export, [:path] => :environment do |t, args|
    args.with_defaults(path: Rails.root.join(Assistant::Export::DEFAULT_ASSISTANT_FILE))
    warn "Exporting assistants to #{args[:path]}"
    unless User.first
      warn "No users found, unable to export assistants"
      exit 1
    end
    assistants = User.first.assistants.ordered.not_deleted
    Assistant.export_to_file(path: args[:path], assistants:)
  end

  desc "Import assistants to all users from a file, defaulting to assistants.yml"
  task :import, [:path] => :environment do |t, args|
    args.with_defaults(path: Rails.root.join(Assistant::Export::DEFAULT_ASSISTANT_FILE))
    warn "Importing assistants from #{args[:path]}"
    users = User.all
    Assistant.import_from_file(path: args[:path], users:)
  end

end

Rake::Task["db:prepare"].enhance do
  Rake::Task["assistants:import"].invoke
end


