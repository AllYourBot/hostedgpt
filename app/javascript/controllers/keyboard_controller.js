import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  click() {
    if (this.elementVisible()) this.element.click()
  }

  elementVisible() {
    return (this.element.offsetParent != null)
  }
}
