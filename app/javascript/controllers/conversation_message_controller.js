"use strict";

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    scrollIntoView: { type: Boolean, default: false }
  }

  connect() {
    if (this.scrollIntoViewValue) {
      const scrollableTarget = this.element.closest('[data-scrollable-target="scrollable"]')

      setTimeout(() => {
        scrollableTarget.scrollTo({
          top: scrollableTarget.scrollHeight,
          behavior: "smooth"
        })
      }, 500) // without the delay sometimes the page hasn't finished rendering and it doesn't go to the bottom
    }
  }
}
