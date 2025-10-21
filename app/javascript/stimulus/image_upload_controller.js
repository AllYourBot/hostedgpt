import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "file", "content", "preview" ]

  connect() {
    if (!this.hasFileTarget || !this.hasContentTarget) {
      console.log("image-upload controller is skipping initialization because a target is missing")
      return
    }

    this.dragCounter = 0
    this.fileTarget.addEventListener("change", this.boundPreviewUpdate)
    this.element.addEventListener("drop", this.boundDropped)
    this.contentTarget.addEventListener("paste", this.boundPasted)
    this.element.addEventListener("dragenter", this.boundDragEnter)
    this.element.addEventListener("dragover", this.boundDragOver)
    this.element.addEventListener("dragleave", this.boundDragLeave)
  }

  disconnect() {
    if (!this.hasFileTarget || !this.hasContentTarget) return

    this.fileTarget.removeEventListener("change", this.boundPreviewUpdate)
    this.element.removeEventListener("drop", this.boundDropped)
    this.contentTarget.removeEventListener("paste", this.boundPasted)
    this.element.removeEventListener("dragenter", this.boundDragEnter)
    this.element.removeEventListener("dragover", this.boundDragOver)
    this.element.removeEventListener("dragleave", this.boundDragLeave)
  }

  boundPreviewUpdate = () => { this.previewUpdate() }
  previewUpdate() {
    if (!this.hasFileTarget || !this.hasPreviewTarget) return

    const input = this.fileTarget
    if (input.files && input.files[0]) {
      const file = input.files[0]
      const reader = new FileReader()
      reader.onload = (e) => {
        const previewContainer = this.previewTarget.querySelector("[data-role='preview']")
        const img = previewContainer.querySelector("img")
        const fileIcon = previewContainer.querySelector("[data-role='file-icon']")

        if (file.type.startsWith('image/')) {
          // Handle image files
          img.src = e.target.result
          img.style.display = 'block'
          if (fileIcon) fileIcon.style.display = 'none'
        } else if (file.type === 'application/pdf') {
          // Handle PDF files
          img.style.display = 'none'
          if (fileIcon) {
            fileIcon.style.display = 'flex'
          } else {
            // Create PDF icon if it doesn't exist
            const pdfIcon = document.createElement('div')
            pdfIcon.setAttribute('data-role', 'file-icon')
            pdfIcon.className = 'w-full h-full flex items-center justify-center bg-red-100 dark:bg-red-900'
            pdfIcon.innerHTML = `
              <svg class="w-8 h-8 text-red-600 dark:text-red-400" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4zm2 6a1 1 0 011-1h6a1 1 0 110 2H7a1 1 0 01-1-1zm1 3a1 1 0 100 2h6a1 1 0 100-2H7z" clip-rule="evenodd"></path>
              </svg>
            `
            previewContainer.appendChild(pdfIcon)
          }
        }

        this.element.classList.add("show-previews")
        this.contentTarget.focus()
        window.dispatchEvent(new CustomEvent('main-column-changed'))
      }
      reader.readAsDataURL(file)
    }
  }

  previewRemove() {
    if (!this.hasPreviewTarget) return

    const previewContainer = this.previewTarget.querySelector("[data-role='preview']")
    const img = previewContainer.querySelector("img")
    const fileIcon = previewContainer.querySelector("[data-role='file-icon']")

    if (img) img.src = ''
    if (fileIcon) fileIcon.style.display = 'none'

    this.element.classList.remove("show-previews")
    if (this.hasContentTarget) this.contentTarget.focus()
    window.dispatchEvent(new CustomEvent('main-column-changed'))
  }

  boundDropped = (event) => { this.dropped(event) }
  dropped(event) {
    if (!this.hasFileTarget) return

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
    if (!this.hasFileTarget) return

    const clipboardData =
      event.clipboardData || event.originalEvent.clipboardData

    for (const item of clipboardData.items) {
      if (item.kind === "file") {
        const blob = item.getAsFile()
        if (!blob) return

        // Only handle images and PDFs
        if (blob.type.startsWith('image/') || blob.type === 'application/pdf') {
          const dataURL = await this.readPastedBlobAsDataURL(blob)
          this.addFileToFileInput(dataURL, blob.type, blob.name || "pasted-file")
        }
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

  addFileToFileInput(dataURL, fileType, fileName) {
    if (!this.hasFileTarget) return

    const fileList = new DataTransfer()
    const blob = this.dataURLtoBlob(dataURL, fileType)

    // Generate appropriate filename based on file type
    let defaultFileName = "pasted-file"
    if (fileType.startsWith('image/')) {
      defaultFileName = "pasted-image.png"
    } else if (fileType === 'application/pdf') {
      defaultFileName = "pasted-document.pdf"
    }

    fileList.items.add(
      new File([blob], fileName || defaultFileName, { type: fileType }),
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
    if (!this.hasFileTarget) return
    this.fileTarget.click()
  }

  remove() {
    if (!this.hasFileTarget) return
    this.fileTarget.value = ''
    this.previewRemove()
  }
}
