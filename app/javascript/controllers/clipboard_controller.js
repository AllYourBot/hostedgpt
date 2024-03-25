import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "text" ]

  copy() {
    navigator.clipboard.writeText(this.text)
    window.clipboard = this.text // useful for automated system tests
  }

  get text() {
    return this.removeExclusions(this.textTarget).innerText
  }

  removeExclusions(node) {
    let clonedNode = node.cloneNode(true)
    clonedNode.querySelectorAll('.clipboard-exclude').forEach(el => el.remove())
    return clonedNode
  }
}
