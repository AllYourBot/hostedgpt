import { Controller } from '@hotwired/stimulus'

// Example:
//
// <div data-controller="radio-behavior" data-radio-behavior-selected-class="bg-red-400">
//   <a href="#" data-radio-behavior-target="radio" data-action="radio-behavior#select">Link #1 acts like radio</a>
//   <a href="#" data-radio-behavior-target="radio" data-action="radio-behavior#select">Link #2 acts like radio</a>
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
//
// Optionally, you can add: data-radio-behavior-also-select-id="123" to any target radio element. This will
// fire a window event with that id which you can listen for on another radio element in order to select it. Be
// sure to add your own listener action for this and include data-radio-behavior-id-param="123" which matches it.
//
// <div data-controller="radio-behavior" data-radio-behavior-selected-class="bg-red-400">
//   <a href="#"
//      data-radio-behavior-target="radio"
//      data-radio-also-select-id="123"
//      data-action="radio-behavior#select">Link acts like radio but also selects id #123</a>
// </div>
//
// <div data-controller="radio-behavior" data-radio-behavior-selected-class="bg-red-400">
//   <a href="#"
//      data-radio-behavior-target="radio"
//      data-radio-id-param="123"
//      data-action="radio-behavior#select radio-changed@window->radio-behavior#select">
//          Link acts like radio but will also be auto-selected by the radio above
//   </a>
// </div>


export default class extends Controller {
  static classes = [ "selected" ]
  static targets = [ "radio" ]

  select(event) {
    let eventTarget

    // This select() can be triggered by a click event or by listening to radio-changed@window
    // The latter has an incorrect event.target so if that's the case we scan the document for
    // the matching id and use that.
    if (event.type == 'radio-changed') {
      if (event.detail.id == event.params.id) {
        eventTarget = document.querySelector(`[data-radio-behavior-id-param="${event.params.id}"]`)
      } else return
    } else
      eventTarget = event.target

    this.radioTargets.forEach(element => {
      element.classList.remove(...this.selectedClasses)
    })

    let radioElement
    if (this.radioTargets.includes(eventTarget))
      radioElement = eventTarget
    else
      radioElement = eventTarget.closest('[data-radio-behavior-target="radio"]')

    radioElement.classList.add(...this.selectedClasses)

    let id = radioElement.getAttribute('data-radio-behavior-also-select-id')
    if (id) window.dispatchEvent(new CustomEvent('radio-changed', { detail: { id: id }}))
  }
}
