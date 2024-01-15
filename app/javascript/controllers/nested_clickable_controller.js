import { Controller } from '@hotwired/stimulus'

export default class extends Controller {

  connect () {
    this.element.addEventListener('mouseover', this.removeParentClickable)
    this.element.addEventListener('mouseout', this.addParentClickable)
  }

  disconnect () {
    this.element.removeEventListener('mouseover')
    this.element.removeEventListener('mouseout')
  }

  removeParentClickable (event) {
    this.parent = event.currentTarget.parentNode.closest('.cursor-pointer')
    this.parent.classList.remove('cursor-pointer')
  }

  addParentClickable (event) {
    this.parent.classList.add('cursor-pointer')
  }
}
