// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { cable } from "@hotwired/turbo-rails"

window.isConnected = true
window.cable = cable
window.consumer = await cable.createConsumer()
setInterval(() => {
  if (consumer.connection.isOpen() != window.isConnected) {
    window.isConnected = consumer.connection.isOpen()
    console.log(`cable ${window.isConnected ? 'connected' : 'DISCONNECTED'}`)
    const elem = document.getElementById('connection-status')
    if (!window.isConnected) {
      if (elem) {
        elem.classList.add('bg-red-400')
        elem.classList.add('text-white')
      }
    } else {
      if (elem) {
        elem.classList.remove('bg-red-400')
        elem.classList.remove('text-white')
        elem.classList.add('text-gray-200')
      }
    }
  }
}, 500)
window.consumer.connection.open()

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
