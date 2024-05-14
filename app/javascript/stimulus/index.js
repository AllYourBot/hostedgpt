// Import and register all your controllers from the importmap under stimulus/*

console.log('initializing stimulus')
import { application } from "stimulus/application"

// Eager load all controllers defined in the import map under stimulus/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("stimulus", application)

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("stimulus", application)
