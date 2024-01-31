import { Controller } from "@hotwired/stimulus"
import debounce from "../utils/debounce.js"

export default class extends Controller {
  static classes = [ "top", "notTop", "bottom", "notBottom" ]
  static targets = [ "scrollable", "widget" ]

  initialize() {
    this.checkScroll()
  }

  debouncedCheckScroll = debounce(this.checkScroll, 50)

  checkScroll() {
    const target = this.scrollableTarget
    const isAtTop = target.scrollTop === 0
    const isAtBottom = target.scrollHeight - target.scrollTop === target.clientHeight

    if (isAtTop) {
      if (this.hasTopClass)       this.widgetTarget.classList.add(this.topClass)
      if (this.hasNotTopClass)    this.widgetTarget.classList.remove(this.notTopClass)
      if (this.hasBottomClass)    this.widgetTarget.classList.remove(this.bottomClass)
      if (this.hasNotBottomClass) this.widgetTarget.classList.add(this.notBottomClass)

    } else if (isAtBottom) {
      if (this.hasTopClass)       this.widgetTarget.classList.remove(this.topClass)
      if (this.hasNotTopClass)    this.widgetTarget.classList.add(this.notTopClass)
      if (this.hasBottomClass)    this.widgetTarget.classList.add(this.bottomClass)
      if (this.hasNotBottomClass) this.widgetTarget.classList.remove(this.notBottomClass)

    } else {
      if (this.hasTopClass)       this.widgetTarget.classList.remove(this.topClass)
      if (this.hasNotTopClass)    this.widgetTarget.classList.add(this.notTopClass)
      if (this.hasBottomClass)    this.widgetTarget.classList.remove(this.bottomClass)
      if (this.hasNotBottomClass) this.widgetTarget.classList.add(this.notBottomClass)
    }
  }

  scrolled() {
    this.debouncedCheckScroll()
  }

  scrollToTop() {
    this.scrollableTarget.scrollTo({
      top: 0,
      behavior: "smooth"
    })
  }

  scrollToBottom() {
    this.scrollableTarget.scrollTo({
      top: this.scrollableTarget.scrollHeight,
      behavior: "smooth"
    })
  }
}
