import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener('turbo:before-morph-element', this.boundSaveValue)
    this.element.addEventListener('turbo:morph-element', this.boundRestoreValue)
    this.savedValue = null
  }

  disconnect() {
    this.element.removeEventListener('turbo:before-morph-element', this.boundSaveValue)
    this.element.removeEventListener('turbo:morph-element', this.boundRestoreValue)
  }

  boundSaveValue = () => { this.saveValue() }
  saveValue() {
    this.savedTarget = this.element.value
  }

  boundRestoreValue = () => { this.restoreValue() }
  restoreValue() {
    this.element.value = this.savedTarget
  }
}
