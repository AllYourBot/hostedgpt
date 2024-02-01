import { Controller } from '@hotwired/stimulus'

// Example:
//
// <div data-controller="radio-behavior" data-radio-behavior-selected-class="bg-red-400">
//   <a href="#" data-action="radio-behavior#select" data-radio-behavior-target="radio">Link #1 acts like radio</a>
//   <a href="#" data-action="radio-behavior#select" data-radio-behavior-target="radio">Link #2 acts like radio</a>
// </div>
//
// Each time one of the radio elements is clicked, it will get the "selected" class and all the others will have
// the class removed.


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
