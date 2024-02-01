import { Controller } from '@hotwired/stimulus'
import debounce from "../utils/debounce.js"

export default class extends Controller {
  static classes = [ "selected" ]
  static targets = [ "radio" ]

  select(event) {
    this.radioTargets.forEach(element => {
      element.classList.remove(...this.selectedClasses)
    })

    event.target.parentNode.classList.add(...this.selectedClasses)
  }
}
