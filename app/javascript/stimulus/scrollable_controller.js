import { Controller } from "@hotwired/stimulus"
import throttle from "stimulus/utils/throttle"

export default class extends Controller {
  static classes = [ "top", "notTop", "bottom", "notBottom" ]
  static targets = [ "scrollable", "widget" ]

  throttledCheckScroll = throttle(() => this.checkScroll(), 50)
  checkScroll() {
    const target = this.scrollableTarget
    const isAtTop = target.scrollTop === 0
    const scrollOffset = target.scrollHeight - target.scrollTop
    const isAtBottom = Math.abs(scrollOffset - target.clientHeight) <= 40 // occasionally these differ by a few pixels

    if (isAtTop && !isAtBottom) {
      window.wasScrolledToBottom = false
      if (this.hasTopClass)       this.widgetTarget.classList.add(this.topClass)
      if (this.hasNotTopClass)    this.widgetTarget.classList.remove(this.notTopClass)
      if (this.hasBottomClass)    this.widgetTarget.classList.remove(this.bottomClass)
      if (this.hasNotBottomClass) this.widgetTarget.classList.add(this.notBottomClass)

    } else if (isAtBottom) { // it might ALSO be at the top, if the page is short, but we count that as bottom
      window.wasScrolledToBottom = true
      if (this.hasTopClass)       this.widgetTarget.classList.remove(this.topClass)
      if (this.hasNotTopClass)    this.widgetTarget.classList.add(this.notTopClass)
      if (this.hasBottomClass)    this.widgetTarget.classList.add(this.bottomClass)
      if (this.hasNotBottomClass) this.widgetTarget.classList.remove(this.notBottomClass)

    } else {
      window.wasScrolledToBottom = false
      if (this.hasTopClass)       this.widgetTarget.classList.remove(this.topClass)
      if (this.hasNotTopClass)    this.widgetTarget.classList.add(this.notTopClass)
      if (this.hasBottomClass)    this.widgetTarget.classList.remove(this.bottomClass)
      if (this.hasNotBottomClass) this.widgetTarget.classList.add(this.notBottomClass)
    }
  }

  scrolled() {
    this.throttledCheckScroll()
  }

  scrollToTop() {
    this.scrollableTarget.scrollTo({
      top: 0,
      behavior: "smooth"
    })
  }

  scrollToBottom() {
    window.wasScrolledToBottom = true // even if we don't get the full way, it was the intention

    this.scrollableTarget.scrollTo({
      top: this.scrollableTarget.scrollHeight,
      behavior: "smooth"
    })
  }
}
