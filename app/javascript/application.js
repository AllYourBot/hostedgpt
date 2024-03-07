// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "stimulus"
import "blocks"
import "blocks/lib/array"
import "blocks/lib/number"
import "blocks/lib/string"

// TODO: Remove this debug code
// This is included in main just for awhile to aid with some debugging
// Also remove "timestamp:" from message broadcasts

let oldTimestamp

document.addEventListener('turbo:before-stream-render', (event) => {
  const stream = event.target
  const newElement = stream.children[0].content.children[0]
  let newTimestamp
  //const oldElement = document.getElementById(newElement.id.toString())
  if (newElement) newTimestamp = parseInt(newElement.getAttribute('data-timestamp'))

  console.log(`${stream.getAttribute('action')} event - ${newTimestamp} ${newTimestamp <= oldTimestamp ? 'REORDER!' : ''}`, stream)
  oldTimestamp = newTimestamp
})
