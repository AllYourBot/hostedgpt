import { Application, defaultSchema } from "@hotwired/stimulus"

const applicationSchema = {
  ...defaultSchema,
  keyMappings: {
    ...defaultSchema.keyMappings,
    "slash": "/",
  }
}

const application = Application.start(document.documentElement, applicationSchema)

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
