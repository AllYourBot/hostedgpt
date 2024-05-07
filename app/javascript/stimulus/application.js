import { Application, defaultSchema } from "@hotwired/stimulus"

const applicationSchema = {
  ...defaultSchema,
  keyMappings: {
    ...defaultSchema.keyMappings,
    "slash": "/",
    "period": "."
  }
}

// TODO: Remove this debug code
// This is included in main just for awhile to aid with some debugging
// Also remove "timestamp:" from message broadcasts

let oldTimestamp

console.log('refresh document')
document.addEventListener('turbo:visit', (event) => console.log(`visit ${event.detail.action}`))
document.addEventListener('turbo:morph', () => console.log('morph render'))
document.addEventListener('turbo:frame-render', () => console.log('frame render'))
document.addEventListener('turbo:before-stream-render', (event) => {
  const stream = event.target
  const newElement = stream.children[0].content.children[0]
  let newTimestamp
  //const oldElement = document.getElementById(newElement.id.toString())
  if (newElement) newTimestamp = parseInt(newElement.getAttribute('data-timestamp'))

  console.log(`stream render (${stream.getAttribute('action')} event) ${newTimestamp <= oldTimestamp ? 'REORDER!' : ''}`, stream)
  oldTimestamp = newTimestamp
})

window.imageLoadingForSystemTestsToCheck = {}
// END debug code

const application = Application.start(document.documentElement, applicationSchema)

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
