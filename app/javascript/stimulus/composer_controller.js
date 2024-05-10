import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "form", "input", "submit", "overlay", "cancel",
    "microphoneEnable", "microphoneDisable" ]

  get cleanInputValue() {
    return this.inputTarget.value.trim()
  }

  connect() {
    this.inputDefaultPlaceholder = this.inputTarget.placeholder
    this.inputTarget.focus()
    this.cursorToEnd()
    this.determineSubmitButton()

    Listener.onConsiderationChanged = async () => {
      this.inputTarget.value = Listener.consideration
      if (Listener.attachment) await this.addAttachment()
      this.submitForm()
    }

    Listener.onProcessingChanged = async (processing) => {
      console.log(`Listener.processing changed to ${processing}`)
    }

    Microphone.onActiveChanged = async (active) => {
      console.log(`Microphone.active changed to ${active}`)
      this.determineMicButton()
    } // TODO: Do I need this? Controls never disable the mic.

    document.addEventListener('turbo:morph', this.boundDetermineMicButton)
    document.addEventListener('turbo:frame-render', this.boundDetermineMicButton)
  }

  disconnect() {
    document.removeEventListener('turbo:morph', this.boundDetermineMicButton)
    document.removeEventListener('turbo:frame-render', this.boundDetermineMicButton)
  }

  cursorToEnd() {
    this.inputTarget.selectionStart =
      this.inputTarget.selectionEnd =
        this.inputTarget.value.length
  }

  determineSubmitButton() {
    if (this.cleanInputValue.length < 1) {
      this.submitTarget.classList.add('hidden')
      if (this.hasCancelTarget) this.cancelTarget.classList.remove('hidden')
    } else {
      this.submitTarget.classList.remove('hidden')
      if (this.hasCancelTarget) this.cancelTarget.classList.add('hidden')
    }
  }

  boundDetermineMicButton = () => { this.determineMicButton() }
  determineMicButton() {
    if (Microphone.on) {
      this.enableMicrophone()
    } else {
      this.disableMicrophone()
    }
  }

  enableMicrophone() {
    this.microphoneEnableTarget.classList.add('hidden')
    this.microphoneDisableTarget.classList.remove('hidden')
    this.disableComposer()
    this.inputTarget.placeholder = "Speak aloud..."
    Flip.Microphone.on()
  }

  disableMicrophone() {
    //if (Microphone.off) return

    this.microphoneEnableTarget.classList.remove('hidden')
    this.microphoneDisableTarget.classList.add('hidden')
    this.enableComposer()
    this.inputTarget.placeholder = this.inputDefaultPlaceholder
    Flip.Microphone.off()
    this.determineSubmitButton()
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
    this.overlayTarget.addEventListener('turbo:before-morph-element', this.boundResetForm, { once: true })
    this.disableComposer()
    this.submitTarget.disabled = true
  }

  disableComposer() {
    this.overlayTarget.classList.remove('hidden')
    this.inputTarget.blur()
  }

  enableComposer() {
    this.overlayTarget.classList.add('hidden')
    this.inputTarget.focus()
  }

  boundResetForm = () => { this.resetForm() }
  resetForm() {
    this.formTarget.reset()
    this.determineSubmitButton()
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

  async addAttachment() {
    if (!Listener.attachment) return

    const data = Listener.attachment.split(';base64,').pop()
		const byteCharacters = atob(data)
		const byteNumbers = new Array(byteCharacters.length)

		for (let i = 0; i < byteCharacters.length; i++) {
			byteNumbers[i] = byteCharacters.charCodeAt(i)
		}

		const byteArray = new Uint8Array(byteNumbers)
		const blob = new Blob([byteArray], {type: 'image/jpeg'})

		const file = new File([blob], "filename.jpg", { type: "image/jpeg" })
		const fileInput = document.querySelector('input[type="file"]')

		const dataTransfer = new DataTransfer()
		dataTransfer.items.add(file)
		fileInput.files = dataTransfer.files

    fileInput.dispatchEvent(new Event('change', { bubbles: true }))
  }
}
