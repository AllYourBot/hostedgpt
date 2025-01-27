import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.lastFocusedElement = null

    document.addEventListener("focusin", this.boundHandleFocusIn)
    document.addEventListener("focusout", this.boundHandleFocusOut)
    document.addEventListener("visibilitychange", this.boundHandleVisibilityChange)
    window.addEventListener("focus", this.boundHandleVisibilityChange)
    window.addEventListener("blur", this.boundHandleVisibilityChange)
  }

  disconnect() {
    document.removeEventListener("focusin", this.boundHandleFocusIn)
    document.removeEventListener("focusout", this.boundHandleFocusOut)
    document.removeEventListener("visibilitychange", this.boundHandleVisibilityChange)
    window.removeEventListener("focus", this.boundHandleVisibilityChange)
    window.removeEventListener("blur", this.boundHandleVisibilityChange)
  }

  boundHandleFocusIn = (event) => { this.handleFocusIn(event) }
  handleFocusIn(event) {
    if (event.target.matches("input, textarea, [contenteditable]")) {
      this.lastFocusedElement = event.target
    }
  }

  boundHandleFocusOut = (event) => { this.handleFocusOut(event) }
  handleFocusOut(event) {
    // Small delay to check if focus moved to another input or was truly lost
    setTimeout(() => {
      if (!document.activeElement.matches("input, textarea, [contenteditable]")) {
        this.lastFocusedElement = null
      }
    }, 0)
  }

  boundHandleVisibilityChange = (event) => { this.handleVisibilityChange(event) }
  handleVisibilityChange(event) {
    if (!document.hidden && this.lastFocusedElement) {
      this.lastFocusedElement.focus()
      if ("selectionStart" in this.lastFocusedElement) {
        this.lastFocusedElement.selectionStart = this.lastFocusedElement.selectionEnd = this.lastFocusedElement.value.length
      }
    }
  }
}
