import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "file", "picker", "content", "previewList", "previewTemplate", "fileInputs" ]

  connect() {
    if (!this.hasFileTarget || !this.hasContentTarget) {
      console.log("image-upload controller is skipping initialization because a target is missing")
      return
    }

    this.entries = []
    this.nextEntryId = 0
    this.nextCloneIndex = 1

    this.dragCounter = 0
    this.fileTarget.addEventListener("change", this.boundPickerChanged)
    this.pickerTarget.addEventListener("change", this.boundPickerChanged)
    this.element.addEventListener("drop", this.boundDropped)
    this.contentTarget.addEventListener("paste", this.boundPasted)
    this.element.addEventListener("dragenter", this.boundDragEnter)
    this.element.addEventListener("dragover", this.boundDragOver)
    this.element.addEventListener("dragleave", this.boundDragLeave)
  }

  disconnect() {
    if (!this.hasFileTarget || !this.hasContentTarget) return

    this.fileTarget.removeEventListener("change", this.boundPickerChanged)
    this.pickerTarget.removeEventListener("change", this.boundPickerChanged)
    this.element.removeEventListener("drop", this.boundDropped)
    this.contentTarget.removeEventListener("paste", this.boundPasted)
    this.element.removeEventListener("dragenter", this.boundDragEnter)
    this.element.removeEventListener("dragover", this.boundDragOver)
    this.element.removeEventListener("dragleave", this.boundDragLeave)
  }

  // The picker is a plain, unnamed <input multiple> used only to trigger the OS file dialog —
  // it's never part of the submitted form. Each file it returns is handed off to its own
  // single-file submission input (fileTarget for the first, a clone for each additional one),
  // so a real Rails-nested-attributes input is never left both "multiple" and empty, which
  // browsers submit as a blank value instead of omitting entirely. fileTarget itself is also
  // watched directly so attaching a file straight to it (e.g. via Capybara) still works.
  boundPickerChanged = (event) => { this.pickerChanged(event) }
  pickerChanged(event) {
    const input = event.target
    const files = Array.from(input.files || [])
    if (input === this.pickerTarget) input.value = ''
    files.forEach((file) => this.addFile(file))
  }

  addFile(file) {
    const entryId = this.nextEntryId++
    const usingFileTarget = !this.entries.some((entry) => entry.input === this.fileTarget)

    let input
    if (usingFileTarget) {
      input = this.fileTarget
    } else {
      const cloneIndex = this.nextCloneIndex++
      input = this.fileTarget.cloneNode(false)
      input.removeAttribute("id")
      input.name = this.fileTarget.name.replace(/\[documents_attributes\]\[\d+\]/, `[documents_attributes][${cloneIndex}]`)
      this.fileInputsTarget.appendChild(input)
    }

    const dataTransfer = new DataTransfer()
    dataTransfer.items.add(file)
    input.files = dataTransfer.files

    const preview = this.buildPreview(file, entryId)
    this.entries.push({ entryId, file, input, preview })
  }

  buildPreview(file, entryId) {
    const clone = this.previewTemplateTarget.content.firstElementChild.cloneNode(true)
    clone.dataset.entryId = entryId

    const removeBtn = clone.querySelector("[data-role='preview-remove']")
    if (removeBtn) removeBtn.dataset.imageUploadIndexParam = entryId

    const img = clone.querySelector("img")
    const fileIcon = clone.querySelector("[data-role='file-icon']")

    if (file.type.startsWith('image/')) {
      const reader = new FileReader()
      reader.onload = (e) => { img.src = e.target.result }
      reader.readAsDataURL(file)
    } else if (file.type === 'application/pdf') {
      img.style.display = 'none'
      if (fileIcon) {
        fileIcon.style.display = 'flex'
      } else {
        const pdfIcon = document.createElement('div')
        pdfIcon.setAttribute('data-role', 'file-icon')
        pdfIcon.className = 'w-full h-full flex items-center justify-center bg-red-100 dark:bg-red-900'
        pdfIcon.innerHTML = `
          <svg class="w-8 h-8 text-red-600 dark:text-red-400" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4zm2 6a1 1 0 011-1h6a1 1 0 110 2H7a1 1 0 01-1-1zm1 3a1 1 0 100 2h6a1 1 0 100-2H7z" clip-rule="evenodd"></path>
          </svg>
        `
        clone.appendChild(pdfIcon)
      }
    }

    this.previewListTarget.appendChild(clone)
    this.element.classList.add("show-previews")
    this.contentTarget.focus()
    window.dispatchEvent(new CustomEvent('main-column-changed'))

    return clone
  }

  removeFile(event) {
    const entryId = parseInt(event.params.index, 10)
    const index = this.entries.findIndex((entry) => entry.entryId === entryId)
    if (index === -1) return

    const entry = this.entries[index]
    entry.preview.remove()

    if (entry.input === this.fileTarget) {
      this.fileTarget.value = ''
    } else {
      entry.input.remove()
    }

    this.entries.splice(index, 1)

    if (this.entries.length === 0) this.element.classList.remove("show-previews")
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

    const files = Array.from(event.dataTransfer.files || []).filter((file) => this.isAllowedType(file))
    files.forEach((file) => this.addFile(file))
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
        if (!blob) continue
        if (!this.isAllowedType(blob)) continue

        const file = new File([blob], blob.name || this.defaultFileName(blob.type), { type: blob.type })
        this.addFile(file)
      }
    }
  }

  isAllowedType(file) {
    return file.type.startsWith('image/') || file.type === 'application/pdf'
  }

  defaultFileName(fileType) {
    return fileType === 'application/pdf' ? 'pasted-document.pdf' : 'pasted-image.png'
  }

  displayDragnDropShade() {
    const existing = this.element.querySelector("#drag-n-drop-shade")
    if (existing) return

    this.element.insertAdjacentHTML(
      'beforeend',
      '<div id="drag-n-drop-shade"></div>'
    );
  }

  choose() {
    if (!this.hasPickerTarget) return
    this.pickerTarget.click()
  }
}
