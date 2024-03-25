import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "submit", "overlay" ]

  get cleanInputValue() {
    return this.inputTarget.value.trim()
  }

  connect() {
    this.inputTarget.focus()
    this.cursorToEnd()
    this.disableSubmitButton()
  }

  cursorToEnd() {
    this.inputTarget.selectionStart =
      this.inputTarget.selectionEnd =
        this.inputTarget.value.length
  }

  // Disable the submit button if the input is empty.
  disableSubmitButton() {
    if (this.cleanInputValue.length < 1) {
      this.submitTarget.disabled = true
    } else {
      this.submitTarget.disabled = false
    }
  }

  submitForm() {
    if (this.cleanInputValue.length > 0) {
      this.disableComposerUntilSubmit()
      this.element.requestSubmit()
      window.dispatchEvent(new CustomEvent('main-column-changed'))
    }
  }

  focusKeydown(event) {
    if (event.key == "/" && ["INPUT", "TEXTAREA"].includes(event.target.tagName)) return

    this.inputTarget.focus()
    event.preventDefault()
  }

  unfocusKeydown(event) {
    document.activeElement.blur()
    event.preventDefault()
  }

  disableComposerUntilSubmit() {
    // While the composer form is being submitted, we want to give the user a visual indicator that the system is
    // processing because slow internet connections can leave you wondering if your submit worked. We do this by
    // putting the composer in a disabled state. However, we do not set .disabled = true because when we do that
    // the HTML of <textarea> is altered and after the submit completes, the morphing detects a change and replaces
    // the <textarea>. This causes it to lose focus.
    //
    // Instead, the solution is to show a semi-transparent overlay. When submit completes, this overlay will be
    // morphed back to being hidden. We listen for that morph and use that as a trigger to clear the text input.
    // This allows the composer to keep focus across multiple chat submits, but it also does not steal the focus
    // back if the user clicks elsewhere while waiting for a server submission to complete.
    this.overlayTarget.addEventListener('turbo:before-morph-element', this.boundEnableComposer, { once: true })
    this.overlayTarget.classList.remove('hidden')
    this.submitTarget.disabled = true
  }

  boundEnableComposer = () => { this.enableComposer() }
  enableComposer() {
    this.inputTarget.value = ''
  }
}
