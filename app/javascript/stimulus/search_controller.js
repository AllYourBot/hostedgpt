import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "clear" ]

  connect() {
    this.cursorToEnd()
    this.setSearchClearIcon()
  }

  cursorToEnd() {
    this.inputTarget.selectionStart =
      this.inputTarget.selectionEnd =
        this.inputTarget.value.length
  }

  clear() {
    this.inputTarget.value = ""
    this.element.requestSubmit()
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 900)
  }

  setSearchClearIcon() {
    if (this.inputTarget.value.length > 0) {
      this.clearTarget.classList.add("text-gray-800")
    } else {
      this.clearTarget.classList.remove("text-gray-800")
    }
  }
}