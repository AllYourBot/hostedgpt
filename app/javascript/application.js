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
// document.addEventListener('turbo:before-stream-render', (event) => {
//   const stream = event.target
//   const newElement = stream.children[0].content.children[0]
//   let newTimestamp
//   //const oldElement = document.getElementById(newElement.id.toString())
//   if (newElement) newTimestamp = parseInt(newElement.getAttribute('data-timestamp'))

//   console.log(`Document: stream render (${stream.getAttribute('action')} event) ${newTimestamp <= oldTimestamp ? 'REORDER!' : ''}`, stream)
//   oldTimestamp = newTimestamp
// })

window.imageLoadingForSystemTestsToCheck = {}
// END debug code


import("blocks").then(() => {
  import("stimulus")
})