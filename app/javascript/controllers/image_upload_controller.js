import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "file", "content", "preview" ]

  connect() {
    this.fileTarget.addEventListener("change", this.boundPreviewUpdate)
    this.contentTarget.addEventListener("dragover", this.boundIgnore)
    this.contentTarget.addEventListener("dragenter", this.boundIgnore)
    this.contentTarget.addEventListener("drop", this.boundDrop)
    this.contentTarget.addEventListener("paste", this.boundPasteHandler)
  }

  disconnect() {
    this.fileTarget.removeEventListener("change", this.boundPreviewUpdate)
    this.contentTarget.removeEventListener("dragover", this.boundIgnore)
    this.contentTarget.removeEventListener("dragenter", this.boundIgnore)
    this.contentTarget.removeEventListener("drop", this.boundDrop)
    this.contentTarget.removeEventListener("paste", this.boundPasteHandler)
  }

  boundPreviewUpdate = () => { this.previewUpdate() }
  previewUpdate() {
    const input = this.fileTarget
    if (input.files && input.files[0]) {
      const reader = new FileReader()
      reader.onload = (e) => {
        this.previewTarget.querySelector("img").src = e.target.result
        this.element.classList.add("show-previews")
        this.contentTarget.focus()
        window.dispatchEvent(new Event('resize')) // Throw this event will cause textarea_autogrow to reprocess
      }
      reader.readAsDataURL(input.files[0])
    }
  }

  previewRemove() {
    this.previewTarget.querySelector("img").src = ''
    this.element.classList.remove("show-previews")
    this.contentTarget.focus()
    window.dispatchEvent(new Event('resize')) // Throw this event will cause textarea_autogrow to reprocess
  }

  boundIgnore = (event) => { this.ignore(event) }
  ignore(event) {
    event.preventDefault()
    event.stopPropagation()
  }

  boundDrop = (event) => { this.drop(event) }
  drop(event) {
    this.preventDefaults(event)
    let files = event.dataTransfer.files
    this.fileTarget.files = files
  }

  boundPasteHandler = async (event) => { this.pasteHandler(event) }
  async pasteHandler(event) {
    const clipboardData =
      event.clipboardData || event.originalEvent.clipboardData

    for (const item of clipboardData.items) {
      if (item.kind === "file") {
        const blob = item.getAsFile()
        if (!blob) return

        try {
          const dataURL = await this.readPastedBlobAsDataURL(blob)
          this.addImageToFileInput(dataURL, blob.type)
        } catch (error) {
          console.error("Error reading pasted image:", error)
        }
      }
    }
  }

  async readPastedBlobAsDataURL(blob) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onload = (event) => {
        resolve(event.target.result)
      }
      reader.onerror = (error) => {
        reject(error)
      }
      reader.readAsDataURL(blob)
    })
  }

  addImageToFileInput(dataURL, fileType) {
    const fileList = new DataTransfer()
    const blob = this.dataURLtoBlob(dataURL, fileType)
    fileList.items.add(
      new File([blob], "pasted-image.png", { type: fileType }),
    )
    this.fileTarget.files = fileList.files
  }

  dataURLtoBlob(dataURL, fileType) {
    const binaryString = atob(dataURL.split(",")[1])
    const arrayBuffer = new ArrayBuffer(binaryString.length)
    const uint8Array = new Uint8Array(arrayBuffer)
    for (let i = 0; i < binaryString.length; i++) {
      uint8Array[i] = binaryString.charCodeAt(i)
    }
    return new Blob([uint8Array], { type: fileType })
  }

  choose() {
    this.fileTarget.click()
  }

  remove() {
    this.fileTarget.value = ''
    this.previewRemove()
  }
}
