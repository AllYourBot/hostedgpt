import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["file", "content"];

  connect() {
    this.dropHandler();
    this.pasteHandler();
  }

  dropHandler() {
    this.fileTarget.addEventListener("dragover", (event) =>
      this.preventDefaults(event),
    );
    this.fileTarget.addEventListener("dragenter", (event) =>
      this.preventDefaults(event),
    );
    this.fileTarget.addEventListener("drop", (event) => this.drop(event));
  }

  preventDefaults(event) {
    event.preventDefault();
    event.stopPropagation();
  }

  drop(event) {
    this.preventDefaults(event);
    let files = event.dataTransfer.files;
    this.fileTarget.files = files;
  }

  pasteHandler() {
    this.contentTarget.addEventListener("paste", async (event) => {
      const clipboardData =
        event.clipboardData || event.originalEvent.clipboardData;

      for (const item of clipboardData.items) {
        if (item.kind === "file") {
          const blob = item.getAsFile();
          if (!blob) return; // return if no valid blob

          try {
            const dataURL = await this.readBlobAsDataURL(blob);
            this.addImageToFileInput(dataURL, blob.type);
          } catch (error) {
            console.error("Error reading pasted image:", error);
          }
        }
      }
    });
  }

  async readBlobAsDataURL(blob) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (event) => {
        resolve(event.target.result);
      };
      reader.onerror = (error) => {
        reject(error);
      };
      reader.readAsDataURL(blob);
    });
  }

  addImageToFileInput(dataURL, fileType) {
    const fileList = new DataTransfer();
    const blob = this.dataURLtoBlob(dataURL, fileType);
    fileList.items.add(
      new File([blob], "pasted-image.png", { type: fileType }),
    );
    this.fileTarget.files = fileList.files;
  }

  dataURLtoBlob(dataURL, fileType) {
    const binaryString = atob(dataURL.split(",")[1]);
    const arrayBuffer = new ArrayBuffer(binaryString.length);
    const uint8Array = new Uint8Array(arrayBuffer);
    for (let i = 0; i < binaryString.length; i++) {
      uint8Array[i] = binaryString.charCodeAt(i);
    }
    return new Blob([uint8Array], { type: fileType });
  }
}
