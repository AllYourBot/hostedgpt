import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "currentAvatar", "previewContainer", "previewImage", "removeButton", "removalNotice"]
  static values = { invalidFileType: String, fileTooLarge: String, confirmRemove: String }

  connect() {
    // Initialize the controller
  }

  chooseFile() {
    this.fileInputTarget.click()
  }

  previewImage(event) {
    const file = event.target.files[0]
    if (!file) return

    // Validate file type
    if (!file.type.match(/^image\/(jpeg|jpg|png|gif|webp)$/)) {
      alert(this.invalidFileTypeValue)
      this.clearFileInput()
      return
    }

    // Validate file size (5MB limit)
    if (file.size > 5 * 1024 * 1024) {
      alert(this.fileTooLargeValue)
      this.clearFileInput()
      return
    }

    // Create preview
    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewImageTarget.src = e.target.result
      this.showPreview()
    }
    reader.readAsDataURL(file)
  }

  removeImage() {
    if (confirm(this.confirmRemoveValue)) {
      this.clearFileInput()
      this.hidePreview()

      if (!this.element.querySelector("input[name='person[personable_attributes][remove_profile_picture]']")) {
        const removeInput = document.createElement('input')
        removeInput.type = 'hidden'
        removeInput.name = 'person[personable_attributes][remove_profile_picture]'
        removeInput.value = '1'
        this.element.appendChild(removeInput)
      }

      this.currentAvatarTarget.classList.add("opacity-30")
      this.removeButtonTarget.classList.add("hidden")
      this.removalNoticeTarget.classList.remove("hidden")
    }
  }

  showPreview() {
    this.previewContainerTarget.classList.remove("hidden")
  }

  hidePreview() {
    this.previewContainerTarget.classList.add("hidden")
  }

  clearFileInput() {
    this.fileInputTarget.value = ""
  }
}
