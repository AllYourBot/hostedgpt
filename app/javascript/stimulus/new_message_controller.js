import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "form", "input", "submit", "overlay", "cancel" ]

  get cleanInputValue() {
    return this.inputTarget.value.trim()
  }

  connect() {
    this.inputTarget.focus()
    this.cursorToEnd()
    this.toggleSubmitButton()
  }

  cursorToEnd() {
    this.inputTarget.selectionStart =
      this.inputTarget.selectionEnd =
        this.inputTarget.value.length
  }

  // Disable the submit button if the input is empty.
  toggleSubmitButton() {
    if (this.cleanInputValue.length < 1) {
      this.submitTarget.disabled = true
      if (this.hasCancelTarget) this.cancelTarget.classList.remove('hidden')
    } else {
      this.submitTarget.disabled = false
      if (this.hasCancelTarget) this.cancelTarget.classList.add('hidden')
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

  submitForm() {
    if (this.cleanInputValue.length > 0) {
      this.disableComposerUntilSubmit()
      this.formTarget.requestSubmit()
      window.dispatchEvent(new CustomEvent('main-column-changed'))
    }
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
    this.formTarget.reset()
  }

  smartPaste(event) {
    event.preventDefault()
    const input = event.target
    const startPos = input.selectionStart
    const endPos = input.selectionEnd
    const clipboardData = event.clipboardData || window.clipboardData
    let pastedData = clipboardData.getData('Text')

    const isAtLineStart = startPos === 0 || input.value.charAt(startPos - 1) === '\n'

    if (isAtLineStart && (pastedData.match(/\n/g) || []).length >= 2) {
      pastedData = '```\n' + pastedData + '\n```\n'
    }

    input.value = input.value.substring(0, startPos) + pastedData + input.value.substring(endPos)
    input.selectionStart = input.selectionEnd = startPos + pastedData.length

    input.dispatchEvent(new Event('input', { bubbles: true }))
  }
}
