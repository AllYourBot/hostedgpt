import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "currentAvatar", "previewContainer", "previewImage"]

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
      alert("Please select a valid image file (JPEG, PNG, GIF, or WebP)")
      this.clearFileInput()
      return
    }

    // Validate file size (5MB limit)
    if (file.size > 5 * 1024 * 1024) {
      alert("File size must be less than 5MB")
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
    if (confirm("Are you sure you want to remove your profile picture?")) {
      this.clearFileInput()
      this.hidePreview()
      
      // Create a hidden input to signal removal
      const removeInput = document.createElement('input')
      removeInput.type = 'hidden'
      removeInput.name = 'person[personable_attributes][remove_profile_picture]'
      removeInput.value = '1'
      this.element.appendChild(removeInput)
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
