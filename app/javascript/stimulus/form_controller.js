import { Controller } from "@hotwired/stimulus"

// Submits the form it is attached to, e.g. from `change->form#submit` on a file field.
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
