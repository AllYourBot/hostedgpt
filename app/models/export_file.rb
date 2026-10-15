class ExportFile
  def self.write(path, storage)
    path = path.to_s
    File.write(path, path.ends_with?(".json") ? storage.to_json : storage.to_yaml)
  end
end
