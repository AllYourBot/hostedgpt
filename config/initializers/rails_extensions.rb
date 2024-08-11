# recursive require of all files in lib/rails_extensions
Dir[File.join(Rails.root, "lib", "rails_extensions", "**/*.rb")].each do |path|
  require path
end
