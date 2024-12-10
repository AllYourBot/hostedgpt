import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "clear" ]

  connect() {
    this.setSearchClearIcon()
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  clear() {
    this.inputTarget.value = ""
    this.element.requestSubmit()
  }

  unfocus() {
    this.inputTarget.autofocus = false
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 900)
  }

  setSearchClearIcon() {
    if (this.inputTarget.value.length > 0) {
      this.clearTarget.classList.remove("hidden")
    } else {
      this.clearTarget.classList.add("hidden")
    }
  }
}