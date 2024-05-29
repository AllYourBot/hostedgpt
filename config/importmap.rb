# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

Dir["app/javascript/**/*"].select do |dir|
  File.directory?(dir) && !dir.include?('/blocks')
end.each do |dir|
  pin_all_from dir, under: dir.remove("app/javascript/") # don't preload: true for stimulus
end

pin "blocks", to: "blocks/index.js", preload: true

Dir["app/javascript/blocks/**/*"].select do |file|
  !File.directory?(file) &&
    !['package.json'].any? { |f| file.include?(f) }
end.each do |file|
  file = file.remove("app/javascript/")
  name = file.remove("blocks/")
  if name.include?('/')
    # Interface and Service models are imported as normal importmap names:
    #   "blocks/interfaces/listener_interface"
    # These are autoimported within blocks/index.js by string parsing the importmap
    pin file.remove('.js'), to: file, preload: true
  else
    # The other JS files within blocks (e.g. readable_model.js) need special importmap names.
    # These files are referenced with explicit 'import' directives at the top of blocks models.
    #   import ReadableModel from "./readable_model.js"
    # To ensure this import directive works both in browser (where importmaps are used) and in
    # node (which does not support importmaps), we name the importmap the relative path
    #   pin file, to: "./readable_model.js"
    pin "/assets/blocks/#{name}", to: file, preload: true
  end
end