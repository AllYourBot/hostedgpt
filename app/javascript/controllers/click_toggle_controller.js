import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static classes = [ "flippable" ]
  static targets = [ "trigger", "destination" ]

  connect () {
    this.triggerTargets.forEach(triggerElement => {

      triggerElement.addEventListener('click', () => {
        console.log(`clicked`, this.flippableClass)
        this.destinationTargets.forEach(element => {
          element.classList.toggle(this.flippableClass)
        })
      })
    })
  }

  disconnect () {
    this.triggerTargets.forEach(triggerElement => {
      triggerElement.removeEventListener('click')
    })
  }
}
