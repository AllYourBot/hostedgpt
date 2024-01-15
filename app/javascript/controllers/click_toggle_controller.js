import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static classes = [ "flippable" ]
  static targets = [ "destination" ]

  connect () {
    console.log('toggle connected', this.flippableClass)
    this.element.addEventListener('mouseover', () => console.log('hovered'))
    this.element.addEventListener('click', () => {
      console.log(`clicked`, this.flippableClass)
      this.destinationTargets.forEach(element => {
        element.classList.toggle(this.flippableClass)
      })
    })
  }

  disconnect () {
    this.element.removeEventListener('click')
  }
}
