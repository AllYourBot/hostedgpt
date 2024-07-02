import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log('## connecting...')
    this.element.addEventListener('turbo:before-morph-element', this.boundSaveValue)
    this.element.addEventListener('turbo:morph-element', this.boundRestoreValue)
    this.savedValue = null
  }

  disconnect() {
    this.element.removeEventListener('turbo:before-morph-element', this.boundSaveValue)
    this.element.removeEventListener('turbo:morph-element', this.boundRestoreValue)
  }

  boundSaveValue = (event) => { this.saveValue(event) }
  saveValue(event) {
    // this.savedValue = event.target.value
    // this.savedTarget = event.target
    // console.log(`## saving value "${event.target.value}" or "${this.element.value}" = `, this.savedValue)
    this.savedTarget = this.element.value
  }

  boundRestoreValue = (event) => { this.restoreValue(event) }
  restoreValue(event) {
    this.element.value = this.savedTarget
    // console.log(`## finding element "${this.savedTarget.id}"`, document.getElementById(`${this.savedTarget.id}`).id)
    // console.log(`## original element: `, this.element.id)
    // console.log(`## target element: `, event.target.id)

    // this.element.value = this.savedValue
    // document.getElementById(`${this.savedTarget.id}`).value = this.savedValue
    // event.target.value = this.savedValue

    // console.log(`## new element set to ${this.element.value} and ${document.getElementById(`${this.savedTarget.id}`).value} and ${event.target.value}`)
  }
}
