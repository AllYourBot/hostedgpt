// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

// TODO: Remove this debug code
// This is included in main just for awhile to aid with some debugging
// Also remove "timestamp:" from message broadcasts

let oldTimestamp

// console.log('Document: refresh')
// document.addEventListener('turbo:visit', (event) => console.log(`Document: visit ${event.detail.action}`))
// document.addEventListener('turbo:morph', () => console.log('Document: morph render'))
// document.addEventListener('turbo:frame-render', () => console.log('Document: frame render'))
// document.addEventListener('turbo:before-stream-render', (event) => console.log(`Document: stream render (${event.target.getAttribute('action')} event)`, event.target, event.detail.newStream.querySelector('template').content?.firstChild?.nextSibling?.querySelector('[data-speaker-target="text assistantText"]')))

window.imageLoadingForSystemTestsToCheck = {}
window.logs = []
// END debug code


import("blocks").then(() => {
  import("stimulus")
})