import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "text" ]

  initialize() {
    window.clipboardForSystemTestsToCheck = ""
  }

  copy() {
    navigator.clipboard.writeText(this.text)
    window.clipboardForSystemTestsToCheck = this.text
  }

  get text() {
    return this.removeExclusions(this.textTarget).innerText?.trim()
  }

  removeExclusions(node) {
    let clonedNode = node.cloneNode(true)
    clonedNode.querySelectorAll('.clipboard-exclude').forEach(el => el.remove())
    return clonedNode
  }
}
