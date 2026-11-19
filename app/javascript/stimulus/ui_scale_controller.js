import { Controller } from "@hotwired/stimulus"

// Sizes the whole interface by setting --ui-scale on <html>, which the stylesheet multiplies into the
// root font size, so everything measured in rem grows or shrinks with it.
//
// It lives on the <body> because Turbo replaces the body on every visit but leaves <html> alone. Each
// new body re-applies the user's saved size, and a page refresh that morphs in a new saved size
// applies it too, so leaving a preview without saving puts the saved size back.
//
// A range input inside the body can preview a size as it's dragged, and show the percent beside it.
//
// Example:
//
// <body
//   data-controller="ui-scale"
//   data-ui-scale-percent-value="120"
// >
//   <input type="range" data-action="input->ui-scale#preview">
//   <span data-ui-scale-target="label">120%</span>
// </body>

export default class extends Controller {
  static targets = [ "label" ]
  static values = { percent: { type: Number, default: 100 } }

  percentValueChanged() {
    this.#apply(this.percentValue)
  }

  preview(event) {
    this.#apply(Number(event.target.value))
  }

  #apply(percent) {
    document.documentElement.style.setProperty("--ui-scale", percent / 100)
    this.labelTargets.forEach(label => label.textContent = `${percent}%`)
  }
}
