import { Controller } from "@hotwired/stimulus"

// Makes a table row behave like a link. The settings index tables use this so the whole row is
// clickable, not just the underlined cell.
//
// <tr data-controller="clickable-row" data-clickable-row-url-value="<%= edit_settings_assistant_path(assistant) %>">

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.element.addEventListener("click", this.boundVisit)
  }

  disconnect() {
    this.element.removeEventListener("click", this.boundVisit)
  }

  boundVisit = () => { this.visit() }
  visit() {
    if (this.hasUrlValue) window.location.href = this.urlValue
  }
}
