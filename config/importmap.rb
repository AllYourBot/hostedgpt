# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

Dir["app/javascript/**/*"].select do |dir|
  File.directory?(dir) && !dir.include?("/blocks")
end.each do |dir|
  pin_all_from dir, under: dir.remove("app/javascript/") # don't preload: true for stimulus
end

pin "blocks", to: "blocks/index.js", preload: true

Dir["app/javascript/blocks/**/*"].select do |file|
  !File.directory?(file) &&
    !["package.json"].any? { |f| file.include?(f) }
end.each do |file|
  file = file.remove("app/javascript/")
  name = file.remove("blocks/")
  if name.include?("/")
    # Interface and Service models are imported as normal importmap names:
    #   "blocks/interfaces/listener_interface"
    # These are autoimported within blocks/index.js by string parsing the importmap
    pin file.remove(".js"), to: file, preload: true
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
pin "tailwindcss-safe-area" # @0.5.1
pin "tailwindcss/plugin", to: "tailwindcss--plugin.js" # @3.4.4
# preload: false: left to the lazy conditional imports inside math/diagram
# controllers (importmap-rails pins default to preload: true)
pin "katex", to: "https://cdn.jsdelivr.net/npm/katex@0.19.0/dist/katex.mjs", integrity: "sha384-jedKqQ2avB8pVdicoYScbJrLo+QCOkeNRKJl9vYz9vRHjP4VYoJFGCelkRVBCZAe", preload: false
pin "katex-auto-render", to: "https://cdn.jsdelivr.net/npm/katex@0.19.0/dist/contrib/auto-render.mjs", integrity: "sha384-TVzn2BhpYt3oVSkcw7UsqrtOiRjYZclHsyRByxnksSdM08YtpNkb7RLhhACRu3OA", preload: false
pin "mermaid", to: "https://cdn.jsdelivr.net/npm/mermaid@12.2.0/dist/mermaid.esm.min.mjs", integrity: "sha384-1zE8eD4a3qmTtl4mMJrmjzEupBhNg25KA88b0P9vQee9I6JEDc8yxcUY4s4pDjuN", preload: false
