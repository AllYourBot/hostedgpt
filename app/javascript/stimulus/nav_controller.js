import { Controller } from '@hotwired/stimulus'

// Opens and closes the nav sidebar, animating it with a View Transition.
//
// The sidebar has two presentations which collapse independently:
//
//   narrow screens: an overlay drawer, opened by the hamburger, closed by tapping the shade
//   wide screens:   a column beside the conversation, toggled by the handle
//
// Both are driven by classes on the <body> so the animation starts on click rather than waiting on
// the server. The wide screen column also remembers itself across page loads, so its handle is a
// form which patches the user. We submit that form ourselves, in the background, rather than letting
// Turbo navigate with it: the page it renders back is one we have already drawn, and while Turbo has
// the form in flight it disables the handle, which swallows a quick second toggle.
//
// Example:
//
// <body
//   data-controller="nav"
//   data-nav-drawer-closed-class="nav-closed"
//   data-nav-column-open-class="nav-open"
// >
//   <button data-action="nav#toggleDrawer">hamburger</button>
//   <a data-action="nav#closeDrawer" href="/somewhere">a link inside the drawer</a>
//   <button data-action="nav#toggleColumn">handle</button>
// </body>

export default class extends Controller {
  static classes = [ "drawerClosed", "columnOpen" ]

  toggleDrawer() {
    this.#transition(this.drawerClosedClass)
  }

  // On a narrow screen the drawer covers the conversation, so following a link inside it has to shut
  // it on the way out, otherwise the page it loads is left hidden behind the drawer. On a wide screen
  // the drawer is already closed (the sidebar is a column there) so this does nothing.
  closeDrawer() {
    if (this.#drawerClosed) return

    this.#transition(this.drawerClosedClass)
  }

  toggleColumn(event) {
    event.preventDefault()
    this.#persistColumn(event.currentTarget.form, !this.#columnOpen)
    this.#transition(this.columnOpenClass)
  }

  #persistColumn(form, open) {
    const field = form?.elements["user[nav_closed]"]
    if (!field) return

    field.value = !open
    fetch(form.action, {
      method: form.method,
      body: new FormData(form),
      redirect: "manual" // the response redirects back to this page, which we have no use for
    }).catch(() => {}) // a sidebar we forgot the position of is not worth bothering anyone about
  }

  #transition(className) {
    if (!this.#animates) return this.#toggle(className)

    document.startViewTransition(() => this.#toggle(className))
  }

  #toggle(className) {
    this.element.classList.toggle(className)

    // Showing and hiding the nav causes the page to flow differently, very similarly to what happens
    // when the browser size changes. Throw this event in case we have other listeners on the resize event.
    window.dispatchEvent(new CustomEvent('main-column-changed'))
  }

  get #drawerClosed() {
    return this.element.classList.contains(this.drawerClosedClass)
  }

  get #columnOpen() {
    return this.element.classList.contains(this.columnOpenClass)
  }

  get #animates() {
    return !!document.startViewTransition &&
      !window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
