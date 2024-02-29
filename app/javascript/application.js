// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

console.log(`binding new replace()`)
let lastElementId = null

document.addEventListener('turbo:before-stream-render', (event) => {
  const stream = event.target
  let newElement, oldElement
  console.log(`event came`, stream)

  if (stream.getAttribute('action') === 'append') {
    console.log(`append?`, stream)
  }

  if (stream.getAttribute('action') === 'replace') {
    newElement = stream.children[0].content.children[0]
    oldElement = document.getElementById(newElement.id.toString())

    if (!newElement.hasAttribute('data-timestamp')) return

    if (!oldElement) {
      console.log('No old element so discarding this one', stream)
      event.preventDefault()
      return
    }

    const oldTimestamp = parseInt(oldElement.getAttribute('data-timestamp') || '0')
    const newTimestamp = parseInt(newElement.getAttribute('data-timestamp'))

    console.log(`${newTimestamp > oldTimestamp ? 'REPLACE' : 'SKIP'} (${newTimestamp} ?> ${oldTimestamp}`)

    if (newTimestamp <= oldTimestamp)
      event.preventDefault()
    else
      oldElement.setAttribute('data-timestamp', newTimestamp)
  }
})
