"use strict";

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    scrollIntoView: { type: Boolean, default: false }
  }

  connect() {
    if (this.scrollIntoViewValue) {
      this.element.scrollIntoView(true, { behavior: "smooth" })
    }
  }
}
