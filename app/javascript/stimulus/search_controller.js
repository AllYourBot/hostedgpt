import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "clear" ]

  inputTargetConnected() {
    this.setSearchClearIcon()
    // Ensure the cursor is at the end of the input
    this.inputTarget.selectionStart =
      this.inputTarget.selectionEnd =
        this.inputTarget.value.length
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
    this.setSearchClearIcon()
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 500)
  }

  setSearchClearIcon() {
    if (this.inputTarget.value.length > 0)
      this.clearTarget.classList.remove("hidden")
    else
      this.clearTarget.classList.add("hidden")
  }
}
