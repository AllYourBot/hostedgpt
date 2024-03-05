# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

Dir["app/javascript/**/*"].select { |d| File.directory?(d) }.each do |dir|
  pin_all_from dir, under: dir.remove("app/javascript/")
end
