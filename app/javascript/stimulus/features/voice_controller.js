import { Controller } from "@hotwired/stimulus"
await importAll('services')
await importAll('controls')
await importAll('triggers')

export default class extends Controller {
  initialize() {
    console.log('init')
    //window.microphoneService = new MicrophoneService()
  }

  connect() {
    //window.microphoneService.start()
  }

  disconnect() {
  }

  considerScroll() {
  }
}

// Private

async function importAll(type) {
  for (const modulePath of allModules(type)) {
    const file = modulePath.split('/').last()
    const className = file.split('_').map(part => part.charAt(0).toUpperCase() + part.slice(1)).join('')
    console.log(`loading: ${modulePath} with ${file} for ${className}`)
    console.log(`const { default: ${className} } = await import("${modulePath}")`)
    const module = await import(modulePath)
    window[className] = module.default
  }
}

function allModules(type) {
  return Object.keys(parseImportmapJson()).filter(path => path.match(new RegExp(`^blocks/${type}/.*$`)))
}

function parseImportmapJson() {
  return JSON.parse(document.querySelector("script[type=importmap]").text).imports
}
