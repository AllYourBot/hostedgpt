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
//
// Note: It's possible that you want the data-action to be on an element which is inside the radio target. One
// reason for this is that you want the selected class to be applied on an outer element wrapping a link. e.g.
//
//   <div data-radio-behavior-target="radio">
//     <a href="#" data-action="radio-behavior#select">This wrapped link acts like a radio</a>
//   </div>
//
// The controller handles this case. It detects that the click event does not have the target applied and finds
// the closest element that has it. You cannot put the data-action on the outer div because stimulus intercepts
// all clicks to a href's and does not bubble them up.


export default class extends Controller {
  static classes = [ "selected" ]
  static targets = [ "radio" ]

  select(event) {
    this.radioTargets.forEach(element => {
      element.classList.remove(...this.selectedClasses)
    })

    if (this.radioTargets.includes(event.target))
      event.target.classList.add(...this.selectedClasses)
    else
      event.target.closest('[data-radio-behavior-target="radio"]').classList.add(...this.selectedClasses)
  }
}
