import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "file", "content", "preview" ]

  connect() {
    this.dragCounter = 0
    this.fileTarget.addEventListener("change", this.boundPreviewUpdate)
    this.element.addEventListener("drop", this.boundDropped)
    this.contentTarget.addEventListener("paste", this.boundPasted)
    this.element.addEventListener("dragenter", this.boundDragEnter)
    this.element.addEventListener("dragover", this.boundDragOver)
    this.element.addEventListener("dragleave", this.boundDragLeave)
  }

  disconnect() {
    this.fileTarget.removeEventListener("change", this.boundPreviewUpdate)
    this.element.removeEventListener("drop", this.boundDropped)
    this.contentTarget.removeEventListener("paste", this.boundPasted)
    this.element.removeEventListener("dragenter", this.boundDragEnter)
    this.element.removeEventListener("dragover", this.boundDragOver)
    this.element.removeEventListener("dragleave", this.boundDragLeave)
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
        window.dispatchEvent(new CustomEvent('main-column-changed'))
      }
      reader.readAsDataURL(input.files[0])
    }
  }

  previewRemove() {
    this.previewTarget.querySelector("img").src = ''
    this.element.classList.remove("show-previews")
    this.contentTarget.focus()
    window.dispatchEvent(new CustomEvent('main-column-changed'))
  }

  boundDropped = (event) => { this.dropped(event) }
  dropped(event) {
    event.preventDefault()
    this.dragCounter = 0
    const shade = this.element.querySelector("#drag-n-drop-shade")
    if (shade) shade.remove()
  
    let files = event.dataTransfer.files
    this.fileTarget.files = files
    this.previewUpdate()
  }

  boundDragOver = (event) => this.dragOver(event)
  dragOver(event) {
    event.preventDefault()
    this.displayDragnDropShade()
  }

  boundDragLeave = (event) => this.dragLeave(event)
  dragLeave(event) {
    event.preventDefault()
    this.dragCounter--
    if (this.dragCounter <= 0) {
      this.dragCounter = 0
      const shade = this.element.querySelector("#drag-n-drop-shade")
      if (shade) shade.remove()
    }
  }

  boundDragEnter = (event) => this.dragEnter(event)
  dragEnter(event) {
    event.preventDefault()
    this.dragCounter++
    this.displayDragnDropShade()
  }

  boundPasted = async (event) => { this.pasted(event) }
  async pasted(event) {
    const clipboardData =
      event.clipboardData || event.originalEvent.clipboardData

    for (const item of clipboardData.items) {
      if (item.kind === "file") {
        const blob = item.getAsFile()
        if (!blob) return

        const dataURL = await this.readPastedBlobAsDataURL(blob)
        this.addImageToFileInput(dataURL, blob.type)
      }
    }
    this.previewUpdate()
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

  displayDragnDropShade() {
    const existing = this.element.querySelector("#drag-n-drop-shade")
    if (existing) return
    
    this.element.insertAdjacentHTML(
      'beforeend',
      '<div id="drag-n-drop-shade"></div>'
    );
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
